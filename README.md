# WireGuard VPN Server

Some third party API providers working with whitelisted IP, even in dev environment. To access their servers we need static IP. This VPN server provides a static IP. We are using this VPN server is a proxy server. Then we can use dev APIs in our local environment.

A simple [WireGuard](https://www.wireguard.com/) VPN server using [wg-easy](https://github.com/wg-easy/wg-easy).

## 🌐 Access Web UI

```txt
http://SERVER_IP:51821
```

### Login

Username: no user, just use password

### Add Client

Add client with '+ New' button then scan QR code or download configuration file.

### Client Apps

Install official client apps from [WireGuard](https://www.wireguard.com/install/?locale=en) website. Then use your client QR or configuration file to connect to the VPN.

> [!WARNING]  
> While using this VPN server, be aware of the security risks. This VPN server is not a secure connection and can be intercepted by third parties. Use only for **development purposes**.

## 📋 Requirements

- Docker & Docker Compose
- Server with public IP
- Ports 51820/UDP and 51821/TCP open

## 🚀 Installation

### Quick Installation

```bash
chmod +x install.sh
./install.sh
```

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

   Edit `.env` and set:
   - `SERVER_IP` - Your server's public IP address
   - `PASSWORD_HASH` - Strong password for admin panel

3. Start the server:

   ```bash
   docker compose up -d
   ```

4. Get password hash:

   ```bash
   docker exec my_awireguard wgpw YOUR_PASSWORD
   ```

   Copy the output and set it to `PASSWORD_HASH` in `.env` file.

5. Apply changes:

   ```bash
   docker compose up -d
   ```

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
