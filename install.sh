#!/bin/bash

#==============================================================================
# Ubuntu Media Streaming Server - Interactive Installer
# Version: 1.0.0
# Description: Automated setup for RTMP to HLS/SRT streaming server on Ubuntu
# Requirements: Ubuntu 20.04+ or Debian 11+ with sudo access
#==============================================================================

set +e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Log file
LOGFILE="$HOME/install_$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="$HOME/streaming_server_backup_$(date +%Y%m%d_%H%M%S)"

#==============================================================================
# Helper Functions
#==============================================================================

log() {
    echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $1" | tee -a "$LOGFILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOGFILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOGFILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOGFILE"
}

print_header() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║       Ubuntu Media Streaming Server - Installer           ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local answer

    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    read -p "$prompt" answer
    answer=${answer:-$default}

    [[ "$answer" =~ ^[Yy]$ ]]
}

press_any_key() {
    read -n 1 -s -r -p "Press any key to continue..."
    echo
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root or with sudo:${NC}"
        echo "  sudo bash install.sh"
        exit 1
    fi
}

create_backup() {
    log_info "Creating backup of existing configurations..."
    mkdir -p "$BACKUP_DIR"

    [ -f /etc/nginx/nginx.conf ] && cp /etc/nginx/nginx.conf "$BACKUP_DIR/"
    [ -f /etc/nginx/streaming-whitelist ] && cp /etc/nginx/streaming-whitelist "$BACKUP_DIR/"

    log "Backup created at: $BACKUP_DIR"
}

#==============================================================================
# Installation Modules
#==============================================================================

install_base_packages() {
    log_info "Installing base packages (nginx, curl, tmux)..."

    apt update >> "$LOGFILE" 2>&1
    if [ $? -ne 0 ]; then
        log_error "Failed to update package list"
        return 1
    fi

    apt install -y nginx curl tmux >> "$LOGFILE" 2>&1
    if [ $? -ne 0 ]; then
        log_error "Failed to install base packages"
        return 1
    fi

    log "✓ Base packages installed successfully"
    return 0
}

install_mistserver() {
    log_info "Installing MistServer..."

    ARCH=$(uname -m)

    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        log_info "Detected ARM64 architecture"
        curl -o - https://releases.mistserver.org/is/mistserver_aarch64V3.10.tar.gz 2>/dev/null | sh >> "$LOGFILE" 2>&1
    elif [ "$ARCH" = "x86_64" ]; then
        log_info "Detected x86_64 architecture"
        curl -o - https://releases.mistserver.org/is/mistserver_64V3.10.tar.gz 2>/dev/null | sh >> "$LOGFILE" 2>&1
    else
        log_error "Unsupported architecture: $ARCH"
        return 1
    fi

    if [ $? -ne 0 ]; then
        log_error "Failed to install MistServer"
        return 1
    fi

    # Enable systemd service
    systemctl enable mistserver >> "$LOGFILE" 2>&1
    systemctl start mistserver >> "$LOGFILE" 2>&1

    log "✓ MistServer installed and started"
    return 0
}

install_web_ui() {
    log_info "Installing Web Proxy Interface..."
    
    local html_dir="/var/www/html"
    mkdir -p "$html_dir"
    
    curl -fsSL https://raw.githubusercontent.com/starskg/ubuntu-media-server/main/web/index.html -o "$html_dir/index.html" >> "$LOGFILE" 2>&1
    curl -fsSL https://raw.githubusercontent.com/starskg/ubuntu-media-server/main/web/style.css -o "$html_dir/style.css" >> "$LOGFILE" 2>&1
    curl -fsSL https://raw.githubusercontent.com/starskg/ubuntu-media-server/main/web/script.js -o "$html_dir/script.js" >> "$LOGFILE" 2>&1
    
    log "✓ Web interface installed"
    return 0
}

configure_nginx() {
    log_info "Configuring Nginx proxy..."

    [ -f /etc/nginx/nginx.conf ] && cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

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

    # DNS resolver
    resolver 8.8.8.8 1.1.1.1 valid=300s;
    resolver_timeout 5s;

    # Extract target host from URL
    map $request_uri $target_host_extracted {
        "~^/live/(?:https?://)?(?<extracted>[^/]+)"  $extracted;
        default "";
    }

    # Verify against whitelist
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
            proxy_hide_header 'Access-Control-Allow-Methods';
            proxy_hide_header 'Access-Control-Allow-Headers';

            if ($request_method = 'OPTIONS') {
                add_header 'Access-Control-Allow-Origin' '*' always;
                add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, HEAD' always;
                add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
                add_header 'Access-Control-Max-Age' 1728000;
                add_header 'Content-Type' 'text/plain; charset=utf-8';
                add_header 'Content-Length' 0;
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

    log_info "Configuring whitelist domains..."

    echo -e "\n${YELLOW}Enter domains to whitelist (comma-separated, or press Enter for localhost only):${NC}"
    echo -e "${BLUE}Example: stream.example.com,cdn.example.com${NC}"
    read -p "> " domains_input

    # Create whitelist file
    cat > /etc/nginx/streaming-whitelist << 'EOF'
# Whitelisted domains
# Syntax: domain_name 1;

EOF

    # Add localhost by default
    echo "localhost:8888   1;" >> /etc/nginx/streaming-whitelist

    # Add user-provided domains
    if [ -n "$domains_input" ]; then
        IFS=',' read -ra DOMAINS <<< "$domains_input"
        for domain in "${DOMAINS[@]}"; do
            domain=$(echo "$domain" | xargs)
            echo "$domain   1;" >> /etc/nginx/streaming-whitelist
            log_info "Added $domain to whitelist"
        done
    fi

    # Option to allow all
    echo -e "\n${YELLOW}Allow ALL domains (not recommended for security)?${NC}"
    if ask_yes_no "Enable unrestricted proxy" "n"; then
        echo "~.*   1;" >> /etc/nginx/streaming-whitelist
        log_warning "Unrestricted proxy enabled"
    fi

    # Test and restart nginx
    nginx -t >> "$LOGFILE" 2>&1
    if [ $? -ne 0 ]; then
        log_error "Nginx configuration test failed"
        return 1
    fi

    systemctl enable nginx >> "$LOGFILE" 2>&1
    systemctl restart nginx >> "$LOGFILE" 2>&1

    log "✓ Nginx configured and started"
    return 0
}

install_filebrowser() {
    log_info "Installing File Browser..."

    curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash >> "$LOGFILE" 2>&1
    if [ $? -ne 0 ]; then
        log_error "Failed to install File Browser"
        return 1
    fi

    # Create systemd service for filebrowser
    cat > /etc/systemd/system/filebrowser.service << 'EOF'
[Unit]
Description=File Browser
After=network.target

[Service]
ExecStart=/usr/local/bin/filebrowser -d /root/filebrowser.db -p 9999 -a 0.0.0.0
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload >> "$LOGFILE" 2>&1
    systemctl enable filebrowser >> "$LOGFILE" 2>&1
    systemctl start filebrowser >> "$LOGFILE" 2>&1

    log "✓ File Browser installed and started on port 9999"
    log_info "Default credentials - Username: admin, Password: admin"
    return 0
}

#==============================================================================
# Main Installation Flow
#==============================================================================

main() {
    check_root
    print_header

    log "Starting installation..."
    log "Log file: $LOGFILE"
    echo

    echo -e "${GREEN}Welcome to the Ubuntu Media Streaming Server installer!${NC}"
    echo -e "This script will set up:"
    echo -e "  • Nginx reverse proxy with CORS support"
    echo -e "  • MistServer for RTMP/HLS/SRT streaming"
    echo -e "  • systemd auto-start configuration"
    echo

    if ! ask_yes_no "Do you want to continue" "y"; then
        log "Installation cancelled by user"
        exit 0
    fi

    echo

    create_backup
    echo

    if ! install_base_packages; then
        log_error "Base package installation failed, but continuing..."
    fi
    echo

    if ! install_mistserver; then
        log_error "MistServer installation failed, but continuing..."
    fi
    echo

    if ! configure_nginx; then
        log_error "Nginx configuration failed, but continuing..."
    fi
    echo
    
    install_web_ui
    echo

    # Optional: File Browser
    echo -e "${YELLOW}Optional: Install File Browser?${NC}"
    echo -e "${BLUE}(Web-based file manager on port 9999)${NC}"
    if ask_yes_no "Install File Browser" "n"; then
        install_filebrowser
        echo
    fi

    # Get server IP
    SERVER_IP=$(hostname -I | awk '{print $1}')

    # Final summary
    print_header
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}           Installation completed successfully!              ${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${YELLOW}Service Status:${NC}"
    echo
    echo -e "🔒 ${BLUE}SSH Access:${NC}"
    echo -e "   ssh $(whoami)@${SERVER_IP}  (port 22)"
    echo
    echo -e "🌐 ${BLUE}Nginx Proxy:${NC}"
    echo -e "   http://${SERVER_IP}:8080"
    echo
    echo -e "🎬 ${BLUE}MistServer Admin:${NC}"
    echo -e "   http://${SERVER_IP}:4242"
    echo
    echo -e "📋 ${BLUE}Proxy URL Format:${NC}"
    echo -e "   http://YOUR_IP:8080/live/TARGET_HOST/PATH"
    echo -e "   Example: http://YOUR_IP:8080/live/localhost:8888/hls/stream.m3u8"
    echo
    echo -e "📡 ${BLUE}Port Forwarding (configure on your router):${NC}"
    echo -e "   TCP 1935  → RTMP Ingest (OBS Studio)"
    echo -e "   TCP 4242  → MistServer Admin Panel"
    echo -e "   TCP 8080  → Nginx Proxy (HLS playback)"
    echo -e "   TCP 22    → SSH Remote Access"
    echo -e "   UDP 8889  → SRT low-latency stream (optional)"
    echo -e "   TCP 9999  → File Browser (if installed)"
    echo
    echo -e "📂 ${BLUE}Backup Location:${NC}"
    echo -e "   $BACKUP_DIR"
    echo
    echo -e "📝 ${BLUE}Installation Log:${NC}"
    echo -e "   $LOGFILE"
    echo
    echo -e "${YELLOW}Useful Commands:${NC}"
    echo -e "  systemctl status nginx        - Nginx status"
    echo -e "  systemctl status mistserver   - MistServer status"
    echo -e "  systemctl restart nginx       - Restart Nginx"
    echo -e "  nginx -s reload               - Reload Nginx config"
    echo -e "  nano /etc/nginx/streaming-whitelist  - Edit whitelist"
    echo
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo

    log "Installation process completed"

    press_any_key
}

# Run main installation
main
