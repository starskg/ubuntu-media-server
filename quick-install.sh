#!/bin/bash

#==============================================================================
# Ubuntu Media Streaming Server - Quick Install (Unattended)
# Version: 1.0.0
# Description: Fully automated installation on Ubuntu/Debian systems
# Requirements: Ubuntu 20.04+ or Debian 11+ with sudo access
#==============================================================================

set +e

# Default settings
DEFAULT_DOMAINS="localhost:8888"
INSTALL_FILEBROWSER=false

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Log file
LOGFILE="$HOME/quick_install_$(date +%Y%m%d_%H%M%S).log"

log() {
    echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $1" | tee -a "$LOGFILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOGFILE"
}

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or with sudo:${NC}"
    echo "  sudo bash quick-install.sh"
    exit 1
fi

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║        Quick Install - Ubuntu Media Streaming Server      ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

log "Starting quick installation..."
log "Log: $LOGFILE"

# Update and install packages
log "Installing packages..."
apt update >> "$LOGFILE" 2>&1
apt install -y nginx curl tmux >> "$LOGFILE" 2>&1

# Install MistServer
log "Installing MistServer..."
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    curl -o - https://releases.mistserver.org/is/mistserver_aarch64V3.10.tar.gz 2>/dev/null | sh >> "$LOGFILE" 2>&1
elif [ "$ARCH" = "x86_64" ]; then
    curl -o - https://releases.mistserver.org/is/mistserver_64V3.10.tar.gz 2>/dev/null | sh >> "$LOGFILE" 2>&1
else
    log_error "Unsupported architecture: $ARCH"
    exit 1
fi

# Configure Nginx
log "Configuring Nginx..."
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup 2>/dev/null || true

cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    map_hash_bucket_size 64;
    sendfile        on;
    keepalive_timeout  65;

    resolver 8.8.8.8 1.1.1.1 valid=300s;
    resolver_timeout 5s;

    map $request_uri $target_host_extracted {
        "~^/live/(?:https?://)?(?<extracted>[^/]+)"  $extracted;
        default "";
    }

    map $target_host_extracted $is_allowed {
        default 0;
        include /etc/nginx/streaming-whitelist;
    }

    server {
        listen 8080;

        location / {
            root /var/www/html;
            index index.html;
        }

        location ~* ^/live/(?:https?://)?(?<target_addr>[0-9.:a-zA-Z-]+)/(?<target_path>.*)$ {

            if ($is_allowed = 0) {
                return 403 "Access Denied: Domain not whitelisted";
            }

            proxy_pass http://$target_addr/$target_path$is_args$args;

            proxy_buffering off;
            proxy_request_buffering off;
            proxy_http_version 1.1;

            proxy_set_header Host $target_addr;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            proxy_hide_header 'Access-Control-Allow-Origin';

            if ($request_method = 'OPTIONS') {
                add_header 'Access-Control-Allow-Origin' '*' always;
                add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
                return 204;
            }

            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, HEAD' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
            add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
        }
    }
}
EOF

echo "localhost:8888 1;" > /etc/nginx/streaming-whitelist

# Test and start Nginx
nginx -t >> "$LOGFILE" 2>&1
systemctl enable nginx >> "$LOGFILE" 2>&1
systemctl restart nginx >> "$LOGFILE" 2>&1

# Enable and start MistServer
log "Enabling MistServer service..."
systemctl enable mistserver >> "$LOGFILE" 2>&1
systemctl start mistserver >> "$LOGFILE" 2>&1

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                 Installation Complete!                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo
echo -e "SSH:        ${BLUE}ssh $(whoami)@${SERVER_IP}${NC}  (port 22)"
echo -e "Nginx:      ${BLUE}http://${SERVER_IP}:8080${NC}"
echo -e "MistServer: ${BLUE}http://${SERVER_IP}:4242${NC}"
echo
echo -e "${YELLOW}📡 Port Forwarding (Router settings):${NC}"
echo -e "  TCP 1935  -> RTMP Ingest (OBS)"
echo -e "  TCP 4242  -> MistServer Admin"
echo -e "  TCP 4200  -> MistServer HTTP"
echo -e "  TCP 8080  -> Nginx Proxy (HLS)"
echo -e "  TCP 22    -> SSH Access"
echo -e "  UDP 8889  -> SRT (low-latency)"
echo
echo -e "${BLUE}Log saved to: $LOGFILE${NC}"
