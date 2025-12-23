#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_banner() {
    printf "${BLUE}"
    echo "╔════════════════════════════════════════════╗"
    echo "║     WireGuard VPN Server Installer         ║"
    echo "╚════════════════════════════════════════════╝"
    printf "${NC}\n"
}

print_success() {
    printf "${GREEN}✓ %s${NC}\n" "$1"
}

print_error() {
    printf "${RED}✗ %s${NC}\n" "$1"
}

print_warning() {
    printf "${YELLOW}! %s${NC}\n" "$1"
}

print_info() {
    printf "${BLUE}→ %s${NC}\n" "$1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check requirements
check_requirements() {
    print_info "Checking requirements..."

    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        echo "  Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    print_success "Docker is installed"

    if ! docker compose version >/dev/null 2>&1; then
        print_error "Docker Compose is not available. Please install Docker Compose."
        echo "  Visit: https://docs.docker.com/compose/install/"
        exit 1
    fi
    print_success "Docker Compose is available"

    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    print_success "Docker daemon is running"

    echo ""
}

# Get server IP
get_server_ip() {
    # Try to detect public IP
    local detected_ip=""
    if command_exists curl; then
        detected_ip=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "")
    fi

    printf "${BLUE}Enter your server's public IP address${NC}\n"
    if [ -n "$detected_ip" ]; then
        printf "  Detected: ${GREEN}%s${NC}\n" "$detected_ip"
        read -p "  Press Enter to use detected IP or enter a different one: " SERVER_IP
        SERVER_IP=${SERVER_IP:-$detected_ip}
    else
        read -p "  IP Address: " SERVER_IP
    fi

    if [ -z "$SERVER_IP" ]; then
        print_error "Server IP is required"
        exit 1
    fi

    print_success "Server IP: $SERVER_IP"
    echo ""
}

# Get password
get_password() {
    printf "${BLUE}Enter a password for the admin panel${NC}\n"
    while true; do
        read -s -p "  Password: " PASSWORD
        echo ""
        read -s -p "  Confirm password: " PASSWORD_CONFIRM
        echo ""

        if [ -z "$PASSWORD" ]; then
            print_error "Password cannot be empty"
            continue
        fi

        if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
            print_error "Passwords do not match. Please try again."
            continue
        fi

        break
    done
    print_success "Password set"
    echo ""
}

# Create .env file
create_env_file() {
    print_info "Creating .env file..."

    cat > .env << EOF
# Docker Compose
COMPOSE_PROJECT_NAME=my_vpn_awg

# Wireguard
SERVER_IP=$SERVER_IP
PASSWORD_HASH=placeholder
EOF

    print_success ".env file created"
}

# Generate password hash
generate_password_hash() {
    print_info "Generating password hash..."

    # Start container temporarily to generate hash
    docker compose up -d >/dev/null 2>&1

    # Wait for container to be ready
    sleep 3

    # Generate hash - wgpw outputs "PASSWORD_HASH='$2a$...'" so we extract just the hash value
    local raw_output=$(docker exec my_awireguard wgpw "$PASSWORD" 2>/dev/null | tail -1)

    # Extract only the hash value (remove PASSWORD_HASH= prefix if present)
    PASSWORD_HASH=$(echo "$raw_output" | sed "s/^PASSWORD_HASH=//")

    if [ -z "$PASSWORD_HASH" ]; then
        print_error "Failed to generate password hash"
        docker compose down >/dev/null 2>&1
        exit 1
    fi

    print_success "Password hash generated"

    # Stop container
    docker compose stop >/dev/null 2>&1
}

# Update .env with password hash
update_env_with_hash() {
    print_info "Updating .env with password hash..."

    # Escape special characters for sed
    ESCAPED_HASH=$(echo "$PASSWORD_HASH" | sed 's/[&/\]/\\&/g')

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|PASSWORD_HASH=placeholder|PASSWORD_HASH=$ESCAPED_HASH|g" .env
    else
        # Linux
        sed -i "s|PASSWORD_HASH=placeholder|PASSWORD_HASH=$ESCAPED_HASH|g" .env
    fi

    print_success ".env updated with password hash"
}

# Start the server
start_server() {
    print_info "Starting WireGuard VPN server..."
    docker compose up -d
    print_success "Server started"
}

# Print completion message
print_completion() {
    echo ""
    printf "${GREEN}╔════════════════════════════════════════════╗${NC}\n"
    printf "${GREEN}║     Installation Complete!                 ║${NC}\n"
    printf "${GREEN}╚════════════════════════════════════════════╝${NC}\n"
    echo ""
    printf "  ${BLUE}Admin Panel:${NC} http://%s:51821\n" "$SERVER_IP"
    printf "  ${BLUE}Login:${NC} Use the password you just set\n"
    echo ""
    printf "  ${YELLOW}Next steps:${NC}\n"
    echo "  1. Open the admin panel in your browser"
    echo "  2. Login with your password"
    echo "  3. Click '+ New' to add a client"
    echo "  4. Scan QR code or download config file"
    echo "  5. Install WireGuard client app: https://www.wireguard.com/install/"
    echo ""
    printf "  ${YELLOW}Useful commands:${NC}\n"
    echo "  docker compose logs -f    # View logs"
    echo "  docker compose stop       # Stop server"
    echo "  docker compose restart    # Restart server"
    echo ""
    print_warning "This VPN is for development purposes only!"
    print_warning "Do not use this VPN for daily jobs to prevent security issues and unnecessary server load."
    echo ""
}

# Main installation flow
main() {
    print_banner
    check_requirements
    get_server_ip
    get_password
    create_env_file
    generate_password_hash
    update_env_with_hash
    start_server
    print_completion
}

# Run main function
main
