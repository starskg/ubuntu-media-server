#!/bin/bash

#==============================================================================
# Service Status Checker - Ubuntu Media Streaming Server
# Description: Displays status of all streaming server services
#==============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_service() {
    local name="$1"
    local service="$2"
    local port="$3"

    echo -n "  $name: "

    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "${GREEN}✓ Running${NC}"
        if [ -n "$port" ]; then
            if ss -tlnp 2>/dev/null | grep -q ":${port} " || nc -z localhost "$port" 2>/dev/null; then
                echo -e "    ${BLUE}Port $port: Open${NC}"
            else
                echo -e "    ${RED}Port $port: Closed${NC}"
            fi
        fi
    else
        echo -e "${RED}✗ Stopped${NC}"
    fi
}

check_process() {
    local name="$1"
    local process="$2"
    local port="$3"

    echo -n "  $name: "

    if pgrep -f "$process" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Running${NC}"
        if [ -n "$port" ]; then
            if ss -tlnp 2>/dev/null | grep -q ":${port} " || nc -z localhost "$port" 2>/dev/null; then
                echo -e "    ${BLUE}Port $port: Open${NC}"
            else
                echo -e "    ${RED}Port $port: Closed${NC}"
            fi
        fi
    else
        echo -e "${RED}✗ Stopped${NC}"
    fi
}

clear
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Ubuntu Streaming Server Status                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}Services:${NC}"
check_service "SSH Server"    "ssh"          "22"
check_service "Nginx Proxy"   "nginx"        "8080"
check_service "MistServer"    "mistserver"   "4242"
check_service "File Browser"  "filebrowser"  "9999"

echo
echo -e "${YELLOW}System Information:${NC}"
echo -e "  Hostname:   ${BLUE}$(hostname)${NC}"
echo -e "  IP Address: ${BLUE}$(hostname -I | awk '{print $1}')${NC}"
echo -e "  Uptime:     ${BLUE}$(uptime -p)${NC}"
echo -e "  OS:         ${BLUE}$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)${NC}"

echo
echo -e "${YELLOW}Resource Usage:${NC}"
echo -e "  CPU:    ${BLUE}$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')% used${NC}"
echo -e "  Memory: ${BLUE}$(free -h | awk '/Mem:/ {printf "%s / %s (%.1f%%)", $3, $2, $3/$2*100}')${NC}"
echo -e "  Disk:   ${BLUE}$(df -h / | awk 'NR==2 {printf "%s / %s (%s used)", $3, $2, $5}')${NC}"

echo
echo -e "${YELLOW}Port Forwarding (Router → this server):${NC}"
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "  TCP 1935 (RTMP)  → $SERVER_IP"
echo -e "  TCP 4242 (Admin) → $SERVER_IP"
echo -e "  TCP 8080 (HLS)   → $SERVER_IP"
echo -e "  TCP 22   (SSH)   → $SERVER_IP"
echo -e "  UDP 8889 (SRT)   → $SERVER_IP"
echo

echo -e "${YELLOW}Quick Actions:${NC}"
echo "  systemctl restart nginx       - Restart Nginx"
echo "  systemctl restart mistserver  - Restart MistServer"
echo "  nginx -s reload               - Reload Nginx config"
echo "  journalctl -u mistserver -f   - Live MistServer logs"
echo "  journalctl -u nginx -f        - Live Nginx logs"
echo

# Health Check
echo -e "${YELLOW}Health Check:${NC}"
issues=0

if ! systemctl is-active --quiet nginx 2>/dev/null; then
    echo -e "  ${RED}⚠${NC} Nginx is not running  →  systemctl start nginx"
    issues=$((issues + 1))
fi

if ! systemctl is-active --quiet mistserver 2>/dev/null; then
    echo -e "  ${RED}⚠${NC} MistServer is not running  →  systemctl start mistserver"
    issues=$((issues + 1))
fi

if ! systemctl is-active --quiet ssh 2>/dev/null && ! systemctl is-active --quiet sshd 2>/dev/null; then
    echo -e "  ${RED}⚠${NC} SSH is not running  →  systemctl start ssh"
    issues=$((issues + 1))
fi

if [ $issues -eq 0 ]; then
    echo -e "  ${GREEN}✓ All systems operational${NC}"
fi

echo
