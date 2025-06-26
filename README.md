# 📷 MJPG-Streamer + Netdata via Docker

Projeto para transmitir vídeo de webcam USB em um Raspberry Pi e monitorar o sistema com Netdata, via Docker.

## ✅ Funcionalidades

- Transmissão ao vivo com MJPG-Streamer
- Monitoramento completo com Netdata
- Acesso via domínio local `http://webcam.local`
- Instalação automatizada com script bash
- Compatível com Raspberry Pi 4

## 🔧 Instalação

```bash
wget https://raw.githubusercontent.com/lucasguilherme/chatgpt-scripts/main/instalar_streamer_netdata.sh
chmod +x instalar_streamer_netdata.sh
sudo ./instalar_streamer_netdata.sh
```

## 🌐 Acesso

- MJPG-Streamer: [http://webcam.local:8080](http://webcam.local:8080)
- Netdata: [http://webcam.local:19999](http://webcam.local:19999)

> 💡 Certifique-se de que o Avahi (Bonjour/mDNS) está instalado em sua rede. Em Windows, basta ter o iTunes ou Apple Bonjour instalado.
