#!/bin/bash

#==============================================================================
# Ubuntu Media Streaming Server - Uninstaller
# Description: Removes all installed components and restores backups
#==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or with sudo:${NC}"
    echo "  sudo bash uninstall.sh"
    exit 1
fi

echo -e "${RED}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║         Ubuntu Streaming Server Uninstaller               ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}This will:${NC}"
echo "  • Stop and disable all services"
echo "  • Remove configuration files"
echo "  • Optionally remove packages"
echo "  • Restore backups (if available)"
echo

read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Uninstallation cancelled."
    exit 0
fi

echo

# Stop and disable services
echo -e "${BLUE}Stopping services...${NC}"
systemctl stop mistserver 2>/dev/null && systemctl disable mistserver 2>/dev/null && echo "✓ MistServer stopped"
systemctl stop nginx 2>/dev/null && echo "✓ Nginx stopped"
systemctl stop filebrowser 2>/dev/null && systemctl disable filebrowser 2>/dev/null && echo "✓ File Browser stopped"

echo

# Find and restore backups
echo -e "${BLUE}Looking for backups...${NC}"
backups=$(find ~/ -maxdepth 1 -type d -name "streaming_server_backup_*" 2>/dev/null)

if [ -n "$backups" ]; then
    echo "Found backups:"
    echo "$backups" | nl
    echo
    read -p "Restore from backup? (y/n): " restore

    if [ "$restore" = "y" ]; then
        latest_backup=$(echo "$backups" | tail -1)
        echo -e "${YELLOW}Restoring from: $latest_backup${NC}"

        [ -f "$latest_backup/nginx.conf" ] && cp "$latest_backup/nginx.conf" /etc/nginx/nginx.conf && echo "✓ Nginx config restored"
        [ -f "$latest_backup/streaming-whitelist" ] && cp "$latest_backup/streaming-whitelist" /etc/nginx/streaming-whitelist && echo "✓ Whitelist restored"
        systemctl restart nginx 2>/dev/null
    fi
else
    echo "No backups found."
fi

echo

# Remove config files
echo -e "${BLUE}Removing configuration files...${NC}"
rm -f /etc/nginx/streaming-whitelist && echo "✓ Removed streaming whitelist"
rm -f /etc/systemd/system/filebrowser.service && echo "✓ Removed File Browser service"
systemctl daemon-reload 2>/dev/null

echo

# Ask about packages
echo -e "${YELLOW}Remove installed packages?${NC}"
echo "This will remove: nginx, filebrowser"
read -p "Continue? (y/n): " remove_pkgs

if [ "$remove_pkgs" = "y" ]; then
    echo -e "${BLUE}Removing packages...${NC}"
    apt remove -y nginx 2>/dev/null
    rm -f /usr/local/bin/filebrowser 2>/dev/null
    echo "✓ Packages removed"
fi

echo

# Ask about MistServer
read -p "Remove MistServer binaries? (y/n): " remove_mist
if [ "$remove_mist" = "y" ]; then
    rm -f /usr/bin/MistController /usr/bin/MistSRT /usr/bin/Mist* 2>/dev/null
    rm -f /etc/systemd/system/mistserver.service 2>/dev/null
    systemctl daemon-reload 2>/dev/null
    echo "✓ MistServer removed"
fi

echo

# Clean up logs
read -p "Remove installation logs? (y/n): " remove_logs
if [ "$remove_logs" = "y" ]; then
    rm -f ~/install_*.log ~/quick_install_*.log 2>/dev/null
    echo "✓ Logs removed"
fi

echo
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Uninstallation Complete!                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${BLUE}What was preserved:${NC}"
echo "  • Backup directories (if any)"
echo "  • User data in home directory"
echo "  • Network settings"
echo
echo -e "${YELLOW}To completely reset, you may also want to:${NC}"
echo "  • Remove port forwarding rules from router"
echo "  • apt autoremove  (clean unused dependencies)"
echo
