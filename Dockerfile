FROM n8nio/n8n:latest

USER root

RUN apt-get update \
 && apt-get install -y --no-install-recommends ffmpeg \
 && rm -rf /var/lib/apt/lists/*

# Switch back to the non-root user used by upstream image
USER node
