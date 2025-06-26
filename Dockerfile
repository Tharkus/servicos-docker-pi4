FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y build-essential cmake git libjpeg62-turbo-dev imagemagick libv4l-dev && \
    git clone https://github.com/jacksonliam/mjpg-streamer.git /opt/mjpg-streamer && \
    cd /opt/mjpg-streamer/mjpg-streamer-experimental && \
    make && make install

WORKDIR /opt/mjpg-streamer/mjpg-streamer-experimental

CMD ["sh", "-c", "exec /usr/local/bin/mjpg_streamer -i \"input_uvc.so -r $RESOLUTION -f $FRAMERATE\" -o \"output_http.so -w /usr/local/share/mjpg-streamer/www -l 0.0.0.0\""]
