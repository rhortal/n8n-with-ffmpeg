FROM n8nio/n8n:latest

USER root

# RUN apt-get update \
#  && apt-get install -y --no-install-recommends ffmpeg \
#  && rm -rf /var/lib/apt/lists/*

RUN wget -q -O /tmp/apk-tools-static.apk https://dl-cdn.alpinelinux.org/alpine/v3.22/main/$(uname -m)/apk-tools-static-2.14.4-r0.apk \
 && tar -xzf /tmp/apk-tools-static.apk -C /tmp \
 && /tmp/sbin/apk.static add apk-tools \
 && rm -rf /tmp/*

RUN apk add --no-cache ffmpeg

# Switch back to the non-root user used by upstream image
USER node
