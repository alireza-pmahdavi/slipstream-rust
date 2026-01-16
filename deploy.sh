#!/bin/bash

# Slipstream Server Setup Script
# This script installs and configures slipstream-rust server on Ubuntu from scratch

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration - EDIT THESE VALUES
DOMAIN="example.com"
TARGET_ADDRESS="127.0.0.1:22"  # Default: SSH
DNS_PORT="53"
INSTALL_DIR="/opt/slipstream"

echo -e "${GREEN}=== Slipstream Server Setup ===${NC}"
echo "Domain: $DOMAIN"
echo "Target: $TARGET_ADDRESS"
echo "DNS Port: $DNS_PORT"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
   echo -e "${RED}Please run as root (use sudo)${NC}"
   exit 1
fi

echo -e "${YELLOW}[1/8] Updating system packages...${NC}"
apt update
apt install -y curl git cmake pkg-config libssl-dev g++ build-essential

echo -e "${YELLOW}[2/8] Installing Rust...${NC}"
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    export PATH="$HOME/.cargo/bin:$PATH"
else
    echo "Rust already installed, updating..."
    rustup update stable
fi

echo -e "${YELLOW}[3/8] Creating installation directory...${NC}"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo -e "${YELLOW}[4/8] Cloning slipstream-rust repository...${NC}"
if [ -d "slipstream-rust" ]; then
    echo "Repository already exists, pulling latest changes..."
    cd slipstream-rust
    git pull
else
    git clone https://github.com/Mygod/slipstream-rust.git
    cd slipstream-rust
fi

echo -e "${YELLOW}[5/8] Initializing submodules...${NC}"
git submodule update --init --recursive

echo -e "${YELLOW}[6/8] Building slipstream (this may take 5-10 minutes)...${NC}"
cargo build --release -p slipstream-server

echo -e "${YELLOW}[7/8] Generating TLS certificates...${NC}"
if [ ! -f "cert.pem" ] || [ ! -f "key.pem" ]; then
    openssl req -x509 -newkey rsa:2048 -nodes \
        -keyout key.pem -out cert.pem -days 365 \
        -subj "/CN=$DOMAIN"
    echo -e "${GREEN}Certificates generated${NC}"
else
    echo "Certificates already exist, skipping..."
fi

echo -e "${YELLOW}[8/8] Creating systemd service...${NC}"
cat > /etc/systemd/system/slipstream-server.service <<EOF
[Unit]
Description=Slipstream DNS Tunnel Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR/slipstream-rust
ExecStart=$INSTALL_DIR/slipstream-rust/target/release/slipstream-server \\
    --dns-listen-port $DNS_PORT \\
    --target-address $TARGET_ADDRESS \\
    --domain $DOMAIN \\
    --cert $INSTALL_DIR/slipstream-rust/cert.pem \\
    --key $INSTALL_DIR/slipstream-rust/key.pem
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

echo ""
echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Make sure UDP port $DNS_PORT is open in your firewall/security group"
echo "2. Configure DNS records:"
echo "   - A record: tns.$DOMAIN → YOUR_SERVER_IP"
echo "   - NS record: $DOMAIN → tns.$DOMAIN"
echo ""
echo -e "${YELLOW}Server management:${NC}"
echo "  Start:   sudo systemctl start slipstream-server"
echo "  Stop:    sudo systemctl stop slipstream-server"
echo "  Status:  sudo systemctl status slipstream-server"
echo "  Logs:    sudo journalctl -u slipstream-server -f"
echo "  Enable on boot: sudo systemctl enable slipstream-server"
echo ""
echo -e "${YELLOW}To start the server now:${NC}"
echo "  sudo systemctl start slipstream-server"
echo ""
echo -e "${GREEN}Binary location: $INSTALL_DIR/slipstream-rust/target/release/slipstream-server${NC}"
echo -e "${GREEN}Certificates: $INSTALL_DIR/slipstream-rust/cert.pem and key.pem${NC}"
