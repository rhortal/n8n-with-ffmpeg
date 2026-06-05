FROM mwader/static-ffmpeg:latest AS ffmpeg

FROM n8nio/n8n:latest

USER root

COPY --from=ffmpeg /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg

USER node
