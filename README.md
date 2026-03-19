# Ubuntu-Based High-Performance Media Streaming Server

**Transforming a standard Ubuntu server into a Dedicated RTMP to HLS/SRT Gateway**

> [!CAUTION]
> **THIS IS NOT PRODUCTION SAFE.** Primarily for **home-labs, development, and personal projects**.

> 🤖 **Looking for the Android/Termux version?** → [android-media-server](https://github.com/starskg/android-media-server)

---

## 📖 Overview

This project sets up a robust, 24/7 streaming media server on **Ubuntu 20.04+** (or Debian 11+) using **Nginx** and **MistServer** managed as native **systemd** services.

### Key Features

- ✅ **Zero Transcoding Load**: Efficient remuxing results in near 0% CPU usage
- ✅ **Custom CORS Handling**: Nginx proxy for web player compatibility
- ✅ **systemd Integration**: Auto-start on boot with crash recovery
- ✅ **Remote Management**: SSH access on port 22
- ✅ **Whitelist Security**: Domain-based access control
- ✅ **Direct Port Forwarding**: Full UDP/TCP support via router
- ✅ **Web File Manager**: Optional File Browser on port 9999
- ✅ **Multi-Architecture**: Supports x86_64 and ARM64

---

## 🏗️ Architecture Stack

| Layer | Component | Role |
|-------|-----------|------|
| **OS** | Ubuntu 20.04+ / Debian 11+ | Host environment |
| **Proxy** | Nginx | HTTP Reverse Proxy & CORS |
| **Media Engine** | MistServer | RTMP Ingest → HLS/SRT Egress |
| **Service Manager** | systemd | Auto-start & Recovery |

---

## 🚀 Quick Start Guide

### One-Command Install

Run this in your terminal and follow the prompts:

```bash
curl -fsSL https://raw.githubusercontent.com/starskg/ubuntu-media-server/main/install.sh | sudo bash
```

### 📋 Main Commands

- **`systemctl status nginx`**: Check Nginx status
- **`systemctl status mistserver`**: Check MistServer status
- **`check-status`**: Check health & ports (with scripts/bashrc)
- **`uninstall`**: Remove components

---

## 📚 Detailed Documentation

For advanced features, security practices, and troubleshooting:

👉 **[Read DOCUMENTATION.md](DOCUMENTATION.md)**

---

## 📡 Port Forwarding

Forward these ports to your server's static local IP:
- **TCP 1935**: RTMP Ingest (OBS)
- **TCP 8080**: Nginx Proxy (HLS)
- **TCP 4242**: MistServer Admin
- **TCP 22**: SSH Access
- **UDP 8889**: SRT (low-latency)

---

## 📧 Contact

**GitHub**: [@starskg](https://github.com/starskg)

**⭐ If you find this project useful, please consider giving it a star!**
