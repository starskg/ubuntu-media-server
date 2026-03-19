# Ubuntu-Based High-Performance Media Streaming Server

**Transforming a standard Ubuntu server into a Dedicated RTMP to HLS/SRT Gateway**

> [!CAUTION]
> **THIS IS NOT PRODUCTION SAFE.** This project is intended for **home-labs, development, and personal projects**. It lacks advanced features like auto-scaling, high-availability clusters, and enterprise-grade firewalls.

---

## 🚀 Quick Installation (Recommended)

One-command setup for **Ubuntu 20.04+** or **Debian 11+**:

```bash
curl -fsSL https://raw.githubusercontent.com/starskg/ubuntu-media-server/main/install.sh | sudo bash
```

### 📋 Main Commands

- **`systemctl status nginx`**: Check Nginx status
- **`systemctl status mistserver`**: Check MistServer status
- **`check-status`**: Check service health and port availability (with scripts/bashrc)
- **`uninstall`**: Remove all project components

---

## 📚 Documentation

Detailed guides, security practices, and architecture details are here:

👉 **[Detailed Documentation (DOCUMENTATION.md)](DOCUMENTATION.md)**

---

## 📡 Port Forwarding (Router Settings)

For external access, forward these ports to your server's static local IP:

| Protocol | Port | Service |
|----------|------|---------|
| TCP | 1935 | RTMP Ingest (OBS Studio) |
| TCP | 8080 | Nginx Proxy (HLS playback) |
| TCP | 4242 | MistServer Admin Panel |
| TCP | 22   | SSH Remote Access |
| UDP | 8889 | SRT (low-latency) |

---

## 🔗 Related Projects

| Project | Platform | Description |
|---------|----------|-------------|
| **[android-media-server](https://github.com/starskg/android-media-server)** | 🤖 Android | Termux/proot setup for Android |
| **[ubuntu-media-server](https://github.com/starskg/ubuntu-media-server)** | 🖥️ Linux | This project (native systemd setup) |

---

## 📧 Contact & Contributions

- **GitHub**: [@starskg](https://github.com/starskg)
- **Issues**: [Report a bug](../../issues)

**⭐ If you find this project useful, please consider giving it a star!**
