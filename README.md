# Download the script
curl -o setup-slipstream.sh https://raw.githubusercontent.com/alireza-pmahdavi/slipstream-rust/refs/heads/main/deploy.sh

# Or create it manually
nano setup-slipstream.sh
# (paste the script content)

# Make it executable
chmod +x setup-slipstream.sh

# Edit configuration at the top of the script
nano setup-slipstream.sh
# Change DOMAIN, TARGET_ADDRESS if needed

# Run it
sudo ./setup-slipstream.sh

After running the script:

# Start the server
sudo systemctl start slipstream-server

# Check status
sudo systemctl status slipstream-server

# View logs
sudo journalctl -u slipstream-server -f

# Enable auto-start on boot
sudo systemctl enable slipstream-server
