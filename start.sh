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
