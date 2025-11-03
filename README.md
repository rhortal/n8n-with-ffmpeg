# n8n + ffmpeg (derived image)

This repository builds a tiny derived n8n image that adds ffmpeg, publishes it to GitHub Container Registry (GHCR), and automatically rebuilds only when the upstream n8n base image changes. The workflow also attempts to set the package visibility to public after a successful push.

Use this repo if you need ffmpeg available inside n8n and want a reproducible, automated, minimal image you control.

Contents
- Dockerfile — builds n8n from the Alpine base and installs ffmpeg
- .github/workflows/build.yml — GitHub Actions workflow that:
  - checks the upstream base-image digest,
  - rebuilds & pushes when the base changes,
  - marks the GHCR package public after push
- base-image-digest.txt — digest tracked by the workflow (created/updated by the workflow)

Quick links (replace OWNER/REPO)
- Image location (GHCR): ghcr.io/OWNER/REPO:latest
- Repo packages page: https://github.com/OWNER/REPO/packages

Prerequisites
- GitHub repo with this code pushed to main
- GitHub Actions enabled
- If you want to pull a private image from another machine: a Personal Access Token (PAT) with read:packages

Quick start — verify the Action ran
1. Push this repo to GitHub (main).
2. In GitHub, go to Actions → select the workflow → view the run logs.
3. Confirm build & push logs from docker/build-push-action show e.g. "pushing to ghcr.io/OWNER/REPO:latest".

If the action completed successfully, the package should appear on:
https://github.com/OWNER/REPO/packages

Files (important ones)
- Dockerfile
  ```Dockerfile
  FROM n8nio/n8n:latest-alpine

  USER root
  RUN apk add --no-cache ffmpeg
  USER node
  ```
- .github/workflows/build.yml
  - Logic:
    - Pulls BASE_IMAGE (env.BASE_IMAGE, default n8nio/n8n:latest-alpine)
    - Reads repo digest, compares with base-image-digest.txt
    - If changed: commits new digest, builds image, pushes to ghcr.io/${{ github.repository }}:latest and :${{ github.sha }}, then attempts to make package public

How to use the image (examples)

- Pull public image:
  docker pull ghcr.io/OWNER/REPO:latest

- If private, log in first (use PAT with read:packages):
  echo "YOUR_PAT" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
  docker pull ghcr.io/OWNER/REPO:latest

- docker-compose (example)
  ```yaml
  version: '3.8'
  services:
    n8n:
      image: ghcr.io/OWNER/REPO:latest
      restart: unless-stopped
      environment:
        - N8N_BASIC_AUTH_ACTIVE=true
        - N8N_BASIC_AUTH_USER=...
        - N8N_BASIC_AUTH_PASSWORD=...
      volumes:
        - n8n-data:/home/node/.n8n

  volumes:
    n8n-data:
  ```

Using Watchtower to auto-update (private image)
- If watchtower is a container and images are private, it needs Docker credentials.
- You can mount your host ~/.docker into the watchtower container and set DOCKER_CONFIG.

Example docker-compose for watchtower:
```yaml
services:
  watchtower:
    image: containrrr/watchtower:latest
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /home/youruser/.docker:/config:ro
    environment:
      - DOCKER_CONFIG=/config
```
Replace /home/youruser with the home of the user that ran `docker login ghcr.io`.

Making GHCR images public (automatic step)
- The workflow attempts to set the package visibility to public after push. That step requires:
  - permissions: packages: write (configured in the workflow)
  - the package to exist and to be owned by the repository owner
- If visibility change fails with 404:
  - Confirm the image was pushed and which account owns it (inspect Actions logs).
  - Ensure the login used during push is the repository owner: the workflow should login using username `${{ github.repository_owner }}` and password `${{ secrets.GITHUB_TOKEN }}`.
  - If images were pushed by a different account previously, you may need to delete those packages and re-run the workflow with corrected login so ownership is correct.

Manually making a package public (UI)
1. Go to: https://github.com/OWNER/REPO/packages
2. Click the package, then Package settings → Change visibility → Public

Scriptable method (gh CLI)
- For a user package:
  gh api -X PATCH /user/packages/container/PACKAGE_NAME/visibility -f visibility=public
- For an org package:
  gh api -X PATCH /orgs/ORG/packages/container/PACKAGE_NAME/visibility -f visibility=public

Host authentication (for private image pulls)
1. Create a PAT on GitHub with scope read:packages (and write:packages if needed).
2. On the host:
   echo "YOUR_PAT" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
3. Confirm:
   docker pull ghcr.io/OWNER/REPO:latest

Important notes and troubleshooting

- First push must succeed
  The package is created on the first push. The visibility-step will 404 until the package exists.

- Ownership matters
  If you log into GHCR during push with a different account than the repository owner, the package may be created under that account. That prevents the repo workflow from changing visibility. Ensure the workflow logs in with:
  username: ${{ github.repository_owner }}
  password: ${{ secrets.GITHUB_TOKEN }}

- If visibility step fails but push succeeded
  Consider making the visibility change a best-effort (non-fatal)—see the workflow to optionally change the behavior.

- If digest detection fails or you want more robust detection
  The workflow uses docker inspect fallbacks. For absolute reliability you can:
  - Track a specific base image tag (not :latest)
  - Query the registry manifest API directly (requires more code)
  - Or pin the base in Dockerfile to a specific tag/digest and update it manually for controlled upgrades.

Customization

- Change base image:
  Edit Dockerfile and env.BASE_IMAGE in the workflow to keep them in sync.

- Use Debian-based n8n:
  Replace FROM line with a Debian tag (e.g. n8nio/n8n:latest) and change the ffmpeg installation to apt commands:
  ```Dockerfile
  USER root
  RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg && rm -rf /var/lib/apt/lists/*
  USER node
  ```

- Multi-arch builds:
  In the build step of the workflow add:
  platforms: linux/amd64,linux/arm64
  plus ensure buildx and QEMU setup steps are included (they are in the provided workflow).

Debugging tips

- Check the build job logs: Actions → your workflow run → build job → steps.
  - Look for docker/login-action and docker/build-push-action output to see push user & tag.
  - Confirm the pushed image name (ghcr.io/OWNER/REPO:tag) and digest.

- List GHCR packages via gh:
  gh api "/users/OWNER/packages?package_type=container" --jq '.[].name'

- Inspect image locally:
  docker pull ghcr.io/OWNER/REPO:latest
  docker inspect ghcr.io/OWNER/REPO:latest

- If you need to delete incorrectly-owned packages:
  - Use the GitHub web UI Packages page → select package → Delete (requires appropriate permissions).

Security notes
- Do not store PATs or other secrets in plain text in the repo.
- For host access, prefer a machine/service user with minimal scopes (read:packages).
- Use repo secrets for automation and the built-in GITHUB_TOKEN for workflow pushes.

FAQs

Q: Why not bind-mount host ffmpeg into the container?
A: You can, but it's fragile (library compatibility) and less reproducible than building the binary into the image.

Q: Why track base-image digest instead of rebuilding daily?
A: Digest-based rebuilds reduce unnecessary builds and only run when upstream actually changed.

Q: Who owns the pushed package?
A: Whoever authenticated to GHCR during `docker push`. For automatic repo-owned packages, authenticate with the repository owner + GITHUB_TOKEN in the workflow.

Contributing
- Fixes and improvements welcome. Open a PR with changes to Dockerfile or Actions.
- If you add codecs or alternative ffmpeg builds, test runtime behavior in a containerized n8n instance.

License
- MIT
  
Contact / Support
- Open issues in this repository for CI/build/workflow problems or usage questions.
