#!/bin/bash

set -e

echo -e "\e[1;34m[INFO]\e[0m Iniciando instalação do Docker, Netdata e MJPG-Streamer..."

LOG_FILE="$HOME/servicos-docker/log_instalacao.txt"
mkdir -p "$HOME/servicos-docker"
cd "$HOME/servicos-docker"

echo -e "\e[1;32m[✔]\e[0m Diretório criado em ~/servicos-docker"
echo "Log da instalação: $LOG_FILE"

exec > >(tee "$LOG_FILE") 2>&1

if [ "$EUID" -ne 0 ]; then
  echo -e "\e[1;31m[ERRO]\e[0m Por favor, execute como root (use sudo)."
  exit 1
fi

apt update
apt install -y docker.io docker-compose git build-essential cmake libjpeg62-turbo-dev imagemagick libv4l-dev avahi-daemon

systemctl enable docker
systemctl start docker
systemctl enable avahi-daemon
systemctl start avahi-daemon

cat <<EOF > docker-compose.yml
services:
  mjpg-streamer:
    build: .
    ports:
      - "8080:8080"
    devices:
      - "/dev/video0:/dev/video0"
    environment:
      - RESOLUTION=\${RESOLUTION}
      - FRAMERATE=\${FRAMERATE}
    restart: unless-stopped

  netdata:
    image: netdata/netdata:latest
    container_name: netdata
    ports:
      - "19999:19999"
    cap_add:
      - SYS_PTRACE
    security_opt:
      - apparmor:unconfined
    restart: unless-stopped
EOF

cat <<EOF > Dockerfile
FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y build-essential cmake git libjpeg62-turbo-dev imagemagick libv4l-dev && \
    git clone https://github.com/jacksonliam/mjpg-streamer.git /opt/mjpg-streamer && \
    cd /opt/mjpg-streamer/mjpg-streamer-experimental && \
    make && make install

WORKDIR /opt/mjpg-streamer/mjpg-streamer-experimental

CMD ["sh", "-c", "exec /usr/local/bin/mjpg_streamer -i \"input_uvc.so -r $RESOLUTION -f $FRAMERATE\" -o \"output_http.so -w /usr/local/share/mjpg-streamer/www -l 0.0.0.0\""]
EOF

cat <<EOF > .env
RESOLUTION=1280x720
FRAMERATE=30
EOF

cat <<EOF > start.sh
#!/bin/bash

echo -e "\n\e[1;36m[INFO]\e[0m Subindo containers Docker...\n"
docker compose up -d --build

sleep 3

echo -e "\n\e[1;33mTestando serviços...\e[0m"

if curl -s --head http://localhost:8080 | grep "200 OK" > /dev/null; then
  echo -e "\e[1;32m[✔]\e[0m MJPG-Streamer em funcionamento: http://localhost:8080"
else
  echo -e "\e[1;31m[ERRO]\e[0m MJPG-Streamer não respondeu corretamente."
fi

if curl -s --head http://localhost:19999 | grep "200 OK" > /dev/null; then
  echo -e "\e[1;32m[✔]\e[0m Netdata em funcionamento: http://localhost:19999"
else
  echo -e "\e[1;31m[ERRO]\e[0m Netdata não respondeu corretamente."
fi

echo -e "\n\e[1;34m[INFO]\e[0m Acesse via navegador usando: http://webcam.local:8080 e http://webcam.local:19999 (Bonjour/mDNS)"
EOF

chmod +x start.sh

./start.sh

echo -e "\n\e[1;32m[✔]\e[0m Instalação completa."
