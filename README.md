Download the script
```
curl -o setup-slipstream.sh https://raw.githubusercontent.com/alireza-pmahdavi/slipstream-rust/refs/heads/main/deploy.sh
chmod +x setup-slipstream.sh
nano setup-slipstream.sh
```
Change DOMAIN

### Run it
```
sudo ./setup-slipstream.sh
```
After running the script:

```
sudo systemctl start slipstream-server
sudo systemctl enable slipstream-server
```
