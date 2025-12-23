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
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     AmneziaWG Kernel Module Installer for Ubuntu           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
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

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_error "This script must be run as root"
        echo "  Please run: sudo $0"
        exit 1
    fi
}

# Check if running on Ubuntu
check_ubuntu() {
    if [ ! -f /etc/os-release ]; then
        print_error "Cannot determine OS. This script is for Ubuntu only."
        exit 1
    fi

    . /etc/os-release

    if [ "$ID" != "ubuntu" ]; then
        print_error "This script is designed for Ubuntu. Detected: $ID"
        exit 1
    fi

    print_success "Ubuntu $VERSION_ID detected"
}

# Ask user if they want to upgrade system
ask_full_upgrade() {
    echo ""
    printf "${YELLOW}System upgrade (optional but recommended):${NC}\n"
    echo "  Running a full system upgrade ensures kernel headers match your kernel."
    echo "  This may require a reboot before continuing."
    echo ""
    read -p "  Do you want to run a full system upgrade? [y/N]: " response

    case "$response" in
        [Yy]|[Yy][Ee][Ss])
            print_info "Running full system upgrade..."
            apt-get update
            apt-get full-upgrade -y
            echo ""
            print_warning "System upgraded. A reboot may be required."
            read -p "  Do you want to reboot now? [y/N]: " reboot_response
            case "$reboot_response" in
                [Yy]|[Yy][Ee][Ss])
                    print_info "Rebooting... Please run this script again after reboot."
                    reboot
                    ;;
            esac
            ;;
        *)
            print_info "Skipping system upgrade"
            ;;
    esac
    echo ""
}

# Configure source repositories
configure_sources() {
    print_info "Checking APT source repositories..."

    local sources_file="/etc/apt/sources.list"
    local sources_dir="/etc/apt/sources.list.d"

    # Check if deb-src is already enabled
    if grep -qE "^deb-src" "$sources_file" 2>/dev/null; then
        print_success "Source repositories already configured"
        return
    fi

    # Check in sources.list.d
    if grep -rqE "^deb-src" "$sources_dir" 2>/dev/null; then
        print_success "Source repositories already configured"
        return
    fi

    # Try to enable source repositories
    print_info "Enabling source repositories..."

    # For Ubuntu 22.04+ with new sources format
    if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
        if grep -q "Types: deb$" /etc/apt/sources.list.d/ubuntu.sources; then
            sed -i 's/Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources
            print_success "Enabled deb-src in ubuntu.sources"
        fi
    elif [ -f "$sources_file" ]; then
        # Traditional sources.list format
        # Uncomment existing deb-src lines or add them
        if grep -qE "^#\s*deb-src" "$sources_file"; then
            sed -i 's/^#\s*deb-src/deb-src/' "$sources_file"
            print_success "Uncommented deb-src lines in sources.list"
        else
            # Add deb-src lines based on existing deb lines
            print_warning "No deb-src lines found. Adding them..."
            grep "^deb " "$sources_file" | sed 's/^deb /deb-src /' >> "$sources_file"
            print_success "Added deb-src lines to sources.list"
        fi
    fi

    apt-get update
}

# Check kernel version and available headers
check_kernel() {
    print_info "Checking kernel version..."

    local running_kernel=$(uname -r)
    print_info "Running kernel: $running_kernel"

    # Get the latest installed kernel
    local latest_kernel=$(ls -1 /boot/vmlinuz-* 2>/dev/null | sort -V | tail -1 | sed 's|/boot/vmlinuz-||')

    if [ -n "$latest_kernel" ] && [ "$latest_kernel" != "$running_kernel" ]; then
        echo ""
        print_warning "Kernel mismatch detected!"
        printf "  Running kernel:   ${RED}%s${NC}\n" "$running_kernel"
        printf "  Installed kernel: ${GREEN}%s${NC}\n" "$latest_kernel"
        echo ""
        print_error "You must reboot into the latest kernel before installing AmneziaWG."
        print_info "The DKMS module will fail to build for an older kernel."
        echo ""
        read -p "  Do you want to reboot now? [Y/n]: " reboot_response
        case "$reboot_response" in
            [Nn]|[Nn][Oo])
                print_error "Please reboot manually and run this script again."
                exit 1
                ;;
            *)
                print_info "Rebooting... Please run this script again after reboot."
                reboot
                ;;
        esac
    fi

    print_success "Kernel version OK: $running_kernel"
}

# Install required packages
install_dependencies() {
    print_info "Installing required packages..."

    apt-get install -y \
        software-properties-common \
        python3-launchpadlib \
        gnupg2 \
        linux-headers-$(uname -r)

    print_success "Dependencies installed"
}

# Fix broken packages if any
fix_broken_packages() {
    print_info "Checking for broken packages..."

    # Check if there are broken packages
    if dpkg --audit 2>/dev/null | grep -q .; then
        print_warning "Found broken packages, attempting to fix..."

        # Try to remove broken amneziawg packages first
        dpkg --remove --force-remove-reinstreq amneziawg 2>/dev/null || true
        dpkg --remove --force-remove-reinstreq amneziawg-dkms 2>/dev/null || true

        # Fix any remaining broken packages
        apt-get -f install -y || true

        print_success "Broken packages handled"
    else
        print_success "No broken packages found"
    fi
}

# Add Amnezia PPA repository
add_ppa() {
    print_info "Adding Amnezia PPA repository..."

    # Check if PPA is already added
    if grep -rq "amnezia/ppa" /etc/apt/sources.list.d/ 2>/dev/null; then
        print_success "Amnezia PPA already configured"
        return
    fi

    add-apt-repository -y ppa:amnezia/ppa
    apt-get update

    print_success "Amnezia PPA added"
}

# Install AmneziaWG
install_amneziawg() {
    print_info "Installing AmneziaWG kernel module..."

    apt-get install -y amneziawg

    print_success "AmneziaWG installed"
}

# Verify installation
verify_installation() {
    print_info "Verifying installation..."

    if modprobe amneziawg 2>/dev/null; then
        print_success "AmneziaWG kernel module loaded successfully"
    else
        print_warning "Could not load kernel module (may require reboot)"
    fi

    if command -v awg &>/dev/null; then
        print_success "awg command is available"
    else
        print_warning "awg command not found in PATH"
    fi

    if command -v awg-quick &>/dev/null; then
        print_success "awg-quick command is available"
    else
        print_warning "awg-quick command not found in PATH"
    fi
}

# Print completion message
print_completion() {
    echo ""
    printf "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${GREEN}║     AmneziaWG Installation Complete!                       ║${NC}\n"
    printf "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}\n"
    echo ""
    printf "  ${BLUE}Installed components:${NC}\n"
    echo "  - AmneziaWG kernel module"
    echo "  - awg (AmneziaWG CLI tool)"
    echo "  - awg-quick (interface management)"
    echo ""
    printf "  ${YELLOW}Usage:${NC}\n"
    echo "  - Create config: /etc/amnezia/amneziawg/awg0.conf"
    echo "  - Start interface: sudo awg-quick up awg0"
    echo "  - Stop interface: sudo awg-quick down awg0"
    echo "  - Check status: sudo awg show"
    echo ""
    printf "  ${YELLOW}Example server config (/etc/amnezia/amneziawg/awg0.conf):${NC}\n"
    echo "  [Interface]"
    echo "  PrivateKey = <server_private_key>"
    echo "  Address = 10.0.0.1/24"
    echo "  ListenPort = 51820"
    echo "  Jc = 4"
    echo "  Jmin = 20"
    echo "  Jmax = 80"
    echo "  S1 = 0"
    echo "  S2 = 0"
    echo "  H1 = 1"
    echo "  H2 = 2"
    echo "  H3 = 3"
    echo "  H4 = 4"
    echo ""
    echo "  [Peer]"
    echo "  PublicKey = <client_public_key>"
    echo "  AllowedIPs = 10.0.0.2/32"
    echo ""
    printf "  ${YELLOW}Generate keys:${NC}\n"
    echo "  - Private key: awg genkey"
    echo "  - Public key: echo <private_key> | awg pubkey"
    echo ""
    print_warning "If the kernel module failed to load, please reboot and try again."
    echo ""
}

# Main installation flow
main() {
    print_banner
    check_root
    check_ubuntu
    ask_full_upgrade
    check_kernel
    fix_broken_packages
    configure_sources
    install_dependencies
    add_ppa
    install_amneziawg
    verify_installation
    print_completion
}

# Run main function
main
