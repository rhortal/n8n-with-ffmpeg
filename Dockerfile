FROM n8nio/n8n:latest

USER root

# RUN apt-get update \
#  && apt-get install -y --no-install-recommends ffmpeg \
#  && rm -rf /var/lib/apt/lists/*

RUN wget -O /tmp/ffmpeg.tar.xz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz && \
    tar -xJf /tmp/ffmpeg.tar.xz -C /tmp && \
    cp /tmp/ffmpeg-*-amd64-static/ffmpeg /usr/local/bin/ && \
    rm -rf /tmp/*

# Switch back to the non-root user used by upstream image
USER node
