FROM n8nio/n8n:latest

ARG ALPINE_VERSION=3.22
ARG APK_TOOLS_STATIC_VERSION=2.14.9-r3

USER root

# RUN apt-get update \
#  && apt-get install -y --no-install-recommends ffmpeg \
#  && rm -rf /var/lib/apt/lists/*

RUN wget -q -O /tmp/apk-tools-static.apk https://dl-cdn.alpinelinux.org/alpine/${ALPINE_VERSION}/main/$(uname -m)/apk-tools-static-${APK_TOOLS_STATIC_VERSION}.apk \
 && tar -xzf /tmp/apk-tools-static.apk -C /tmp \
 && /tmp/sbin/apk.static add apk-tools \
 && rm -rf /tmp/*

RUN apk add --no-cache ffmpeg

# Switch back to the non-root user used by upstream image
USER node
