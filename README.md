# Amnezia WireGuard VPN Server

A simple [WireGuard](https://www.wireguard.com/) VPN server using [wg-easy](https://github.com/wg-easy/wg-easy) and [AmneziaWG Linux kernel module](https://github.com/amnezia-vpn/amneziawg-linux-kernel-module).

> [!WARNING]  
> This setup still uses beta `ghcr.io/wg-easy/wg-easy:15.2.0-beta.3` image and kernel module `amneziawg`. You can use it for testing purposes but it is not recommended for production use.

## Why Amnezia?

AmneziaWG is an enhanced version of the WireGuard VPN protocol designed to bypass Deep Packet Inspection (DPI) and advanced network traffic analysis systems. It maintains WireGuard's high speed and security while adding obfuscation parameters (Jc, Jmin, Jmax, S1, S2, H1-H4) to packet headers, making VPN traffic indistinguishable from regular internet traffic. This open-source, free solution allows users to set up their own VPN on personal servers with complete control, eliminating reliance on third-party VPN providers.

## 🌐 Access Web UI

```txt
http://SERVER_IP:51821
```

### Login

Username: no user, just use password

### Add Client

Add client with '+ New' button then scan QR code or download configuration file.

### Client Apps

Install official client [AmneziaWG](https://github.com/wg-easy/wg-easy/blob/master/docs/content/advanced/config/amnezia.md#client-applications) app. Then use your client QR or configuration file to connect to the VPN.

> [!WARNING]  
> While using this VPN server, be aware of the security risks. This VPN server is not a secure connection and can be intercepted by third parties. Use only for **development purposes**.

## 📋 Requirements

- Docker & Docker Compose
- Server with public IP
- Ports 51820/UDP and 51821/TCP open

## 🚀 Installation

### Amnezia WireGuard Installation

```bash
chmod +x install-amneziawg-ubuntu.sh
./install-amneziawg-ubuntu.sh
```

### What this script does?

- System Preparation (Steps 1-2):

   Optional system upgrade with apt-get full-upgrade
   Enables deb-src repositories required for building kernel modules
- Prerequisites Installation (Step 3):

   Installs essential packages: software-properties-common, python3-launchpadlib, gnupg2, linux-headers, build-essential, and dkms
- Repository Configuration (Step 4):

   Adds the official Amnezia PPA repository using add-apt-repository ppa:amnezia/ppa
- AmneziaWG Installation (Step 5):

   Installs the amneziawg package which includes the kernel module
- Verification (Step 6):

   Checks if the kernel module is available using modinfo
   Attempts to load the module with modprobe
   Verifies tools installation
- Network Configuration (Step 7):

   Enables IPv4 and IPv6 forwarding in /etc/sysctl.conf for VPN routing functionality
- Post-Installation (Steps 8-9):

   Creates secure configuration directory at /etc/amneziawg
   Displays configuration parameters and usage instructions.

Finally restart your server to apply changes.

### Manual Installation

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd vpn-server
   ```

2. Configure environment:

   ```bash
   cp .env.example .env
   ```

3. Start the server:

   ```bash
   docker compose up -d
   ```

4. Register new user:

   - Go to http://SERVER_IP:51821
   - Register new user

Now you can access the admin panel.

## 📖 Usage

1. Access admin panel: `http://<SERVER_IP>:51821`
2. Login with your configured password
3. Create a new client and download/scan the QR code
4. Import configuration into WireGuard client app

## 🔌 Ports

| Port  | Protocol | Purpose         |
|-------|----------|-----------------|
| 51820 | UDP      | WireGuard VPN   |
| 51821 | TCP      | Web Admin UI    |

## ⌨️ Commands

```bash
# Start
docker compose up -d

# Stop
docker compose stop

# View logs
docker compose logs -f

# Restart
docker compose restart
```

> [!IMPORTANT]  
> If you run `docker compose down`, it will remove the container and the volume. So you need to run `docker compose up -d` again to start the container. Otherwise, you will lose your clients etc.
