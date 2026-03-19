# Detailed Documentation - Ubuntu Media Streaming Server

This document provides in-depth architecture, security, and advanced configuration details for the Ubuntu/Debian-based media streaming gateway.

---

## 🏗️ Architecture Stack

Native Linux setup using standard system services for high reliability:

| Layer | Component | Role |
|-------|-----------|------|
| **OS** | Ubuntu 20.04+ / Debian 11+ | Host operating system |
| **Proxy** | Nginx | HTTP reverse proxy, CORS, whitelist |
| **Media Engine** | MistServer | RTMP ingest → HLS/SRT egress |
| **Service Manager** | systemd | Auto-start, crash recovery |
| **Remote Access** | OpenSSH | SSH on port 22 |
| **Optional** | File Browser | Web-based file manager |

---

## 💡 Real-World Use Cases

Practical examples to help you understand the project's purpose:

1.  **IPTV Proxy & Relay:** Transmux external IPTV streams on your local network and distribute them to various devices (Smart TV, Mobile) in HLS format.
2.  **OBS Gateway:** Send an RTMP stream from your computer (OBS Studio) to your server and use your setup as a "global gateway" to relay the stream to multiple CDNs or web players simultaneously.
3.  **Home Media CDN:** Create an HLS/SRT endpoint to view home videos or live broadcasts with low-latency within the local network (or externally via port forwarding).
4.  **Scaling Streamers:** Use your Ubuntu server as a high-performance ingest point for multiple cameras or OBS sources.

---

## ⚡ Core Engine: MistServer

Powered by **MistServer**, a low-overhead media server built for performance.

**Why MistServer?**
- 🚀 **Performance:** Handles hundreds of streams with minimal CPU usage.
- 🔄 **Transmuxing:** Instant path for RTMP to HLS/SRT without raw transcoding.
- 📡 **Multi-Protocol:** Support for RTMP, HLS, SRT, DASH, MP3/4.
- 🛠️ **systemd Native:** Runs as a standard system service.

Official site: [mistserver.org](https://mistserver.org).

---

## 🔒 Security Best Practices

> [!IMPORTANT]
> **NEVER IGNORE SECURITY!** Default credentials on an open port is a significant vulnerability.

1.  **System Password:** Ensure your Ubuntu user has a complex password. Use SSH Key-based authentication for remote access.
2.  **MistServer Admin:** Set a strong username and password in the admin panel (`http://IP:4242`) immediately after installation.
3.  **Whitelist Management:** Manage your trusted domains in `/etc/nginx/streaming-whitelist`. Avoid `~.* 1;` (catch-all rules).
4.  **UFW Firewall:** Enable UFW and only allow necessary ports:
    ```bash
    sudo ufw allow 22/tcp
    sudo ufw allow 1935/tcp
    sudo ufw allow 8080/tcp
    sudo ufw allow 4242/tcp
    sudo ufw enable
    ```

---

## 🛠️ Manual Installation Guide

<details>
<summary><b>Click to expand manual steps</b></summary>

### Step 1: Base Packages
```bash
sudo apt update && sudo apt install -y nginx curl tmux
```

### Step 2: Install MistServer
```bash
# x86_64:
curl -o - https://releases.mistserver.org/is/mistserver_64V3.10.tar.gz | sudo sh

# ARM64:
curl -o - https://releases.mistserver.org/is/mistserver_aarch64V3.10.tar.gz | sudo sh
```

### Step 3: Nginx Config
Edit `/etc/nginx/nginx.conf` and add the proxy settings from the repo's `config/nginx/nginx.conf`.

### Step 4: Whitelist Site
Create `/etc/nginx/streaming-whitelist`:
```nginx
localhost:8888 1;
```

</details>

---

## 🔍 Troubleshooting & Services

### Direct Logs
- Nginx: `sudo journalctl -u nginx -f`
- MistServer: `sudo journalctl -u mistserver -f`

### Control
- Restart: `sudo systemctl restart nginx mistserver`
- Status: `sudo systemctl status nginx`

---

## 🗺️ Roadmap & Version History

- **v1.0.0 (Latest):** Fixed Cloudflare UDP issues, switched to port forwarding, added security docs, split documentation files.
