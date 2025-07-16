#!/bin/bash

set -e

echo -e "\e[1;34m[INFO]\e[0m Iniciando instalação personalizada..."

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

# Instalação de dependências
apt update
apt install -y docker.io docker-compose git build-essential cmake libjpeg62-turbo-dev imagemagick libv4l-dev avahi-daemon

# Habilita e inicia o Docker e o Avahi
systemctl enable docker
systemctl start docker
systemctl enable avahi-daemon
systemctl start avahi-daemon

echo -e "\e[1;36m[INFO]\e[0m Docker e dependências instaladas."

# Função para instalar o MJPG-Streamer
install_mjpg_streamer() {
  echo -e "\e[1;32m[✔]\e[0m Instalando MJPG-Streamer..."
  
  cat <<EOF > docker-compose.yml
services:
  mjpg-streamer:
    build: .
    ports:
      - "8080:8080"
    devices:
      - "/dev/video0:/dev/video0"
    environment:
      - RESOLUTION=${RESOLUTION}
      - FRAMERATE=${FRAMERATE}
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
}

# Função para instalar o Netdata
install_netdata() {
  echo -e "\e[1;32m[✔]\e[0m Instalando Netdata..."

  cat <<EOF > docker-compose.yml
services:
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
}

# Função para instalar o Portainer
install_portainer() {
  echo -e "\e[1;32m[✔]\e[0m Instalando Portainer..."

  cat <<EOF > docker-compose.yml
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    ports:
      - "9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    restart: unless-stopped

volumes:
  portainer_data:
EOF
}

# Função para instalar o Home Assistant
install_home_assistant() {
  echo -e "\e[1;32m[✔]\e[0m Instalando Home Assistant..."

  cat <<EOF > docker-compose.yml
services:
  home-assistant:
    image: homeassistant/home-assistant:latest
    container_name: home-assistant
    ports:
      - "8123:8123"
    volumes:
      - home_assistant_data:/config
    restart: unless-stopped

volumes:
  home_assistant_data:
EOF
}

# Função para instalar o Nextcloud
install_nextcloud() {
  echo -e "\e[1;32m[✔]\e[0m Instalando Nextcloud..."

  cat <<EOF > docker-compose.yml
services:
  nextcloud:
    image: nextcloud:latest
    container_name: nextcloud
    ports:
      - "8080:80"
    volumes:
      - nextcloud_data:/var/www/html
    restart: unless-stopped

volumes:
  nextcloud_data:
EOF
}

# Função para instalar o Transmission
install_transmission() {
  echo -e "\e[1;32m[✔]\e[0m Instalando Transmission..."

  cat <<EOF > docker-compose.yml
services:
  transmission:
    image: transmission:latest
    container_name: transmission
    ports:
      - "9091:9091"
    volumes:
      - transmission_data:/var/lib/transmission
    restart: unless-stopped

volumes:
  transmission_data:
EOF
}

# Função para instalar o Pi-hole
install_pihole() {
  echo -e "\e[1;32m[✔]\e[0m Instalando Pi-hole..."

  cat <<EOF > docker-compose.yml
services:
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    ports:
      - "80:80"
    environment:
      - TZ="America/Sao_Paulo"
      - WEBPASSWORD="admin"
    volumes:
      - pihole_data:/etc/pihole
    restart: unless-stopped

volumes:
  pihole_data:
EOF
}

# Função para instalar o Grafana
install_grafana() {
  echo -e "\e[1;32m[✔]\e[0m Instalando Grafana..."

  cat <<EOF > docker-compose.yml
services:
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    restart: unless-stopped

volumes:
  grafana_data:
EOF
}

# Função para instalar o Jellyfin
install_jellyfin() {
  echo -e "\e[1;32m[✔]\e[0m Instalando Jellyfin..."

  cat <<EOF > docker-compose.yml
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    ports:
      - "8096:8096"
    volumes:
      - jellyfin_data:/config
      - jellyfin_media:/media
    restart: unless-stopped

volumes:
  jellyfin_data:
  jellyfin_media:
EOF
}

# Função para instalar o Nginx Proxy Manager
install_nginx_proxy_manager() {
  echo -e "\e[1;32m[✔]\e[0m Instalando Nginx Proxy Manager..."

  cat <<EOF > docker-compose.yml
services:
  nginx-proxy-manager:
    image: jc21/nginx-proxy-manager:latest
    container_name: nginx-proxy-manager
    ports:
      - "81:81"
    volumes:
      - nginx_proxy_manager_data:/config
    restart: unless-stopped

volumes:
  nginx_proxy_manager_data:
EOF
}

# Perguntar ao usuário quais serviços ele quer instalar
echo -e "\e[1;33m[INFO]\e[0m Selecione os serviços que deseja instalar:"
echo "1) MJPG-Streamer"
echo "2) Netdata"
echo "3) Portainer"
echo "4) Home Assistant"
echo "5) Nextcloud"
echo "6) Transmission"
echo "7) Pi-hole"
echo "8) Grafana"
echo "9) Jellyfin"
echo "10) Nginx Proxy Manager"
echo "11) Todos os serviços"
read -p "Digite os números separados por espaço (ex: 1 2 3): " services

# Instalar os serviços selecionados
for service in $services; do
  case $service in
    1) install_mjpg_streamer ;;
    2) install_netdata ;;
    3) install_portainer ;;
    4) install_home_assistant ;;
    5) install_nextcloud ;;
    6) install_transmission ;;
    7) install_pihole ;;
    8) install_grafana ;;
    9) install_jellyfin ;;
    10) install_nginx_proxy_manager ;;
    11) 
      install_mjpg_streamer
      install_netdata
      install_portainer
      install_home_assistant
      install_nextcloud
      install_transmission
      install_pihole
      install_grafana
      install_jellyfin
      install_nginx_proxy_manager
      ;;
    *)
      echo -e "\e[1;31m[ERRO]\e[0m Opção inválida: $service"
      ;;
  esac
done

# Executar os containers
echo -e "\e[1;36m[INFO]\e[0m Subindo os containers..."
docker-compose up -d --build

echo -e "\n\e[1;32m[✔]\e[0m Instalação completa."
