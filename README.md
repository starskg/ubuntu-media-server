**Transforming a standard Ubuntu server into a Dedicated RTMP to HLS/SRT Gateway**

> [!CAUTION]
> **THIS IS NOT PRODUCTION SAFE.** This project is intended for **home-labs, development, and personal projects**. It lacks advanced features like auto-scaling, high-availability clusters, enterprise-grade firewalls, and rigorous security hardening necessary for large-scale production environments.

> 🤖 **Looking for the Android/Termux version?** → [android-media-server](https://github.com/starskg/android-media-server)

---

## 📖 Overview

This project sets up a robust, 24/7 streaming media server on **Ubuntu 20.04+** (or Debian 11+). It establishes a pipeline that ingests RTMP streams (e.g., from OBS Studio) and transmuxes them into HLS or SRT formats for delivery.

The setup uses **Nginx** as a reverse proxy with CORS support and **MistServer** as the core media engine — both managed as native **systemd** services.

---

## 💡 Real-World Use Cases

Why should you use this project? Here are some practical examples:

1.  **IPTV Proxy & Relay:** Transmux external IPTV streams on your local network and distribute them to various devices (Smart TV, Mobile) in HLS format.
2.  **OBS Gateway:** Send an RTMP stream from your computer (OBS Studio) to your server and use your setup as a "global gateway" to relay the stream to multiple CDNs or web players simultaneously.
3.  **Home Media CDN:** Create an HLS/SRT endpoint to view home videos or live broadcasts with low-latency within the local network (or externally via port forwarding).

---

## ⚡ Core Engine: MistServer

This streaming gateway is powered by **MistServer**, an advanced, open-source multimedia server designed for high-performance delivery.

**Why MistServer?**
- 🚀 **Performance:** Extremely low overhead, perfect for handling hundreds of streams on a single server.
- 🔄 **Transmuxing:** Native stream re-packaging (no heavy transcoding required).
- 📡 **Multi-Protocol:** One-stop support for RTMP, HLS, SRT, DASH, MP3/4, and custom HTTP.
- 🛠️ **systemd Native:** Runs effortlessly as a system service with automatic recovery.

Check official docs: [mistserver.org](https://mistserver.org).

---

### Key Features

- ✅ **Zero Transcoding Load**: Efficient remuxing results in near 0% CPU usage
- ✅ **Custom CORS Handling**: Nginx configured as a reverse proxy for web player compatibility
- ✅ **systemd Integration**: Auto-start on boot with crash recovery
- ✅ **Remote Management**: SSH access (port 22)
- ✅ **Whitelist Security**: Domain-based access control for proxy endpoints
- ✅ **Direct Port Forwarding**: Full UDP/TCP support via router port forwarding (no tunnel restrictions)
- ✅ **Web File Manager**: Optional built-in file browser on port 9999
- ✅ **Automated Installation**: One-command setup with interactive configuration
- ✅ **Multi-Architecture**: Supports both x86_64 and ARM64

---

## 🏗️ Architecture Stack

| Layer | Component | Role |
|-------|-----------|------|
| **OS** | Ubuntu 20.04+ / Debian 11+ | Host operating system |
| **Proxy** | Nginx | HTTP reverse proxy, CORS, whitelist |
| **Media Engine** | MistServer | RTMP ingest → HLS/SRT egress |
| **Service Manager** | systemd | Auto-start, crash recovery |
| **Remote Access** | OpenSSH | SSH on port 22 |
| **Optional** | File Browser | Web-based file manager |

---

## 🔒 Security Best Practices

> [!IMPORTANT]
> **NEVER IGNORE SECURITY!** Exposing your server to the open internet with default or weak credentials is high risk.

1.  **Ubuntu Password:** Ensure your system user password is sufficiently complex. Preferably, configure SSH Key-based authentication for remote access.
2.  **MistServer Admin:** Immediately after installation, access the MistServer admin panel (`http://IP:4242`) to set a unique username and a complex password.
3.  **Whitelist Management:** Keep only trusted domains in your Nginx whitelist (`/etc/nginx/streaming-whitelist`). Avoid using the catch-all `~.* 1;` rule.
4.  **UFW Firewall:** Enable UFW and allow only the necessary ports:
    ```bash
    sudo ufw allow 22/tcp
    sudo ufw allow 1935/tcp
    sudo ufw allow 8080/tcp
    sudo ufw allow 4242/tcp
    sudo ufw enable
    ```

---

## 🚀 Quick Installation (Recommended)

### One-Command Install

```bash
curl -fsSL https://raw.githubusercontent.com/starskg/ubuntu-media-server/main/install.sh | sudo bash
```

**Or download first, then run:**

```bash
# Download the installer
curl -O https://raw.githubusercontent.com/starskg/ubuntu-media-server/main/install.sh

# Make it executable
chmod +x install.sh

# Run the installer
sudo bash install.sh
```

### What the Installer Does

1. ✅ **Updates packages** and installs required software
2. ✅ **Installs MistServer** (auto-detects x86_64 or ARM64)
3. ✅ **Configures Nginx** reverse proxy with CORS support
4. ✅ **Asks for whitelist domains** (which sites to allow)
5. ✅ **Enables systemd** services for auto-start on boot
6. ✅ **Optional:** File Browser for web-based file management
7. ✅ **Creates auto-start** configuration
8. ✅ **Backs up** existing configurations

### Installation Process

**Step 1:** Connect to your Ubuntu server via SSH

**Step 2:** Run the installation command:
```bash
sudo bash install.sh
```

**Step 3:** Follow the interactive prompts:

```
Welcome to the Ubuntu Media Streaming Server installer!
...
Do you want to continue? [Y/n]: y

Installing base packages...
✓ Base packages installed successfully

Installing MistServer...
Detected x86_64 architecture
✓ MistServer installed and started

Configuring Nginx proxy...

Enter domains to whitelist (comma-separated, or press Enter for localhost only):
Example: stream.example.com,cdn.example.com
> stream.example.com,localhost:8888

Allow ALL domains (not recommended for security)?
Enable unrestricted proxy [y/N]: n

✓ Nginx configured and started

Optional: Install File Browser?
(Web-based file manager on port 9999)
Install File Browser [y/N]: y

✓ File Browser installed and started on port 9999
```

**Step 4:** Wait for completion (2-5 minutes)

### Post-Installation

After installation completes, you'll see:

```
════════════════════════════════════════════════════════════
           Installation completed successfully!
════════════════════════════════════════════════════════════

🔒 SSH Access:
   ssh root@203.0.113.10  (port 22)

🌐 Nginx Proxy:
   http://203.0.113.10:8080

🎬 MistServer Admin:
   http://203.0.113.10:4242

📋 Proxy URL Format:
   http://YOUR_IP:8080/live/TARGET_HOST/PATH
   Example: http://YOUR_IP:8080/live/localhost:8888/hls/stream.m3u8

📡 Port Forwarding (configure on your router):
   TCP 1935  → RTMP Ingest (OBS Studio)
   TCP 4242  → MistServer Admin Panel
   TCP 8080  → Nginx Proxy (HLS playback)
   TCP 22    → SSH Remote Access
   UDP 8889  → SRT low-latency stream (optional)
   TCP 9999  → File Browser (if installed)
```

---

## ⚡ Alternative: Fully Automated Install

For servers without interaction:

```bash
curl -fsSL https://raw.githubusercontent.com/starskg/ubuntu-media-server/main/quick-install.sh | sudo bash
```

**Default settings:**
- Whitelist: `localhost:8888` only
- No optional components

---

## 🌐 Networking & Port Forwarding

For external access, configure your router to forward traffic to the server's static local IP.

| Protocol | Port | Service | Description |
|----------|------|---------|-------------|
| TCP | 1935 | RTMP Ingest | Accepts video streams from OBS Studio |
| TCP | 4242 | MistServer API | Web administration panel access |
| TCP | 8080 | Nginx Proxy | Main proxy endpoint for HLS/SRT playback |
| TCP | 8888 | HTTP/HLS Egress | Direct MistServer port (internal) |
| UDP | 8889 | SRT | For low-latency SRT streams |
| TCP | 9999 | File Browser | Web-based file management interface |
| TCP | 22   | SSH | Remote terminal access |

---

## 🌐 Using the Proxy

### URL Format

```
http://YOUR_SERVER_IP:8080/live/TARGET_HOST/PATH
```

### Examples

```bash
# Access MistServer on localhost
http://203.0.113.10:8080/live/localhost:8888/hls/stream.m3u8

# Access external stream server
http://203.0.113.10:8080/live/stream.example.com:8080/live/channel1.m3u8

# With full HTTP URL (auto-extracted)
http://203.0.113.10:8080/live/http://cdn.example.com/stream/playlist.m3u8
```

### Managing Whitelist

Edit allowed domains:

```bash
sudo nano /etc/nginx/streaming-whitelist
```

Add domains:
```nginx
stream.example.com   1;
cdn.example.com      1;
localhost:8888       1;
```

Reload Nginx:
```bash
sudo nginx -s reload
```

> ⚠️ **Security:** Only whitelist trusted domains to prevent your server from becoming an open proxy.

---

## 🔧 Service Management

### Check Status

```bash
# Download and run status checker
curl -fsSL https://raw.githubusercontent.com/starskg/ubuntu-media-server/main/check-status.sh | sudo bash
```

Or use the alias (after adding scripts/bashrc to your ~/.bashrc):
```bash
check-status
```

### Manual Control

```bash
# Nginx
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo nginx -s reload          # Reload config without restart

# MistServer
sudo systemctl start mistserver
sudo systemctl stop mistserver
sudo systemctl restart mistserver

# File Browser
sudo systemctl start filebrowser
sudo systemctl stop filebrowser

# View logs
sudo journalctl -u nginx -f
sudo journalctl -u mistserver -f
```

---

## 📁 Optional: File Browser

If you installed File Browser, access it at:

```
http://YOUR_SERVER_IP:9999
```

**Default credentials:**
- Username: `admin`
- Password: `admin`

**Change password:**
```bash
filebrowser users update admin --password NEW_PASSWORD -d /root/filebrowser.db
```

---

## 🐛 Troubleshooting

### Services not running

Check status:
```bash
sudo systemctl status nginx
sudo systemctl status mistserver
```

Restart manually:
```bash
sudo systemctl restart nginx
sudo systemctl restart mistserver
```

### 403 Forbidden errors

Domain not whitelisted. Add to `/etc/nginx/streaming-whitelist`:
```bash
sudo nano /etc/nginx/streaming-whitelist
# Add: yourdomain.com 1;
sudo nginx -s reload
```

### Nginx config test

```bash
sudo nginx -t
```

### View live logs

```bash
# Nginx errors
sudo journalctl -u nginx -f

# MistServer logs
sudo journalctl -u mistserver -f
```

### Check which ports are open

```bash
sudo ss -tlnp | grep -E '1935|4242|8080|8889|9999|22'
```

---

## 🗑️ Uninstallation

```bash
curl -fsSL https://raw.githubusercontent.com/starskg/ubuntu-media-server/main/uninstall.sh | sudo bash
```

The uninstaller will:
- Stop and disable all services
- Restore backups
- Optionally remove packages
- Clean up files

---

## 📊 Performance

MistServer uses direct transmuxing (RTMP → HLS/SRT) with **no transcoding**, resulting in near-zero CPU load regardless of the number of viewers.

---

## 📖 Manual Installation Guide

<details>
<summary><b>Click here for detailed manual installation steps</b></summary>

---

### Step 1: System Update

```bash
sudo apt update && sudo apt upgrade -y
```

---

### Step 2: Install Nginx

```bash
sudo apt install -y nginx curl tmux
sudo systemctl enable nginx
sudo systemctl start nginx
```

**Edit the main Nginx configuration:**

```bash
sudo nano /etc/nginx/nginx.conf
```

**Paste the full configuration** (see [config/nginx/nginx.conf](config/nginx/nginx.conf) in this repository)

**Create the streaming whitelist:**

```bash
sudo nano /etc/nginx/streaming-whitelist
```

```nginx
# ADD ALLOWED SITES TO THIS FILE
# Syntax: domain_name 1;
localhost:8888   1;
```

**Reload Nginx:**

```bash
sudo nginx -t && sudo systemctl reload nginx
```

---

### Step 3: Install MistServer

```bash
# For x86_64:
curl -o - https://releases.mistserver.org/is/mistserver_64V3.10.tar.gz 2>/dev/null | sudo sh

# For ARM64:
curl -o - https://releases.mistserver.org/is/mistserver_aarch64V3.10.tar.gz 2>/dev/null | sudo sh

# Enable and start
sudo systemctl enable mistserver
sudo systemctl start mistserver
```

---

### Step 4: Add Shell Aliases (Optional)

```bash
cat scripts/bashrc >> ~/.bashrc
source ~/.bashrc
```

---

### Optional: Install File Browser

```bash
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | sudo bash
```

Create systemd service:
```bash
sudo nano /etc/systemd/system/filebrowser.service
```

```ini
[Unit]
Description=File Browser
After=network.target

[Service]
ExecStart=/usr/local/bin/filebrowser -d /root/filebrowser.db -p 9999 -a 0.0.0.0
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable filebrowser
sudo systemctl start filebrowser
```

---

</details>

---

## 📂 Project Structure

```
.
├── install.sh                  # Interactive installer (recommended)
├── quick-install.sh            # Fully automated installer
├── uninstall.sh                # Uninstaller script
├── check-status.sh             # Service status checker
├── config/
│   └── nginx/
│       ├── nginx.conf          # Main Nginx configuration
│       └── websites            # Whitelist file template
├── scripts/
│   └── bashrc                  # Shell aliases and helpers
└── README.md
```

---

## 📜 License

This project configuration is open-source under the MIT License. MistServer itself follows its own licensing terms.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](../../issues).

**How to contribute:**

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📧 Contact

For questions or collaboration:

- **GitHub**: [@starskg](https://github.com/starskg)
- **Issues**: [Report a bug](../../issues/new)

---

## 🙏 Acknowledgments

- **MistServer** - Efficient media streaming engine
- **Nginx** - High-performance web server
- **PRoot** - User-space implementation of chroot

---

## ⚠️ Disclaimer

This setup is intended for personal/educational use. Ensure compliance with your ISP's terms of service and local regulations regarding server hosting. The authors are not responsible for any misuse or damage caused by this configuration.

---

**⭐ If you find this project useful, please consider giving it a star!**

---

## 📝 Version History

- **v1.0.0** (2026-03-19)
  - Initial release based on android-media-server
  - Ubuntu/Debian adaptation (systemd, apt, native MistServer)
  - Multi-architecture support (x86_64 + ARM64)
  - Direct port forwarding (full UDP/TCP support)
  - Optional File Browser via systemd

---

## 🗺️ Roadmap

- [ ] Web-based installation UI
- [ ] Docker Compose support
- [ ] Stream recording automation
- [ ] Grafana monitoring dashboard
- [ ] Automated SSL/TLS setup (Let's Encrypt)
- [ ] Multi-language documentation
- [ ] Automated backup system

---

## 🔗 Related Projects

| Project | Platform | Description |
|---------|----------|-------------|
| **[android-media-server](https://github.com/starskg/android-media-server)** | 🤖 Android (Termux) | Termux/proot based setup for Android devices |
| **[ubuntu-media-server](https://github.com/starskg/ubuntu-media-server)** | 🖥️ Ubuntu / Debian | This project — Native systemd-based setup for Linux servers |
