FROM n8nio/n8n:latest

USER root

RUN ARCH=$(uname -m) && \
    case $ARCH in \
        x86_64) FFMPEG_ARCH=amd64 ;; \
        aarch64) FFMPEG_ARCH=arm64 ;; \
        i686) FFMPEG_ARCH=i686 ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    wget -O /tmp/ffmpeg.tar.xz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-${FFMPEG_ARCH}-static.tar.xz && \
    tar -xJf /tmp/ffmpeg.tar.xz -C /tmp && \
    cp /tmp/ffmpeg-*-${FFMPEG_ARCH}-static/ffmpeg /usr/local/bin/ && \
    rm -rf /tmp/*

# Switch back to the non-root user used by upstream image
USER node
