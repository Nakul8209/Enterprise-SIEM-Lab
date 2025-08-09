#!/bin/bash
# Simple Wazuh Server Installation - What you actually used

# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install curl apt-transport-https unzip wget libcap2-bin software-properties-common gnupg -y

# Add Wazuh repository
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor | sudo tee /usr/share/keyrings/wazuh-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/wazuh-archive-keyring.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list

sudo apt update

# Install Wazuh components
sudo apt install wazuh-manager -y
sudo apt install wazuh-indexer -y
sudo apt install wazuh-dashboard -y

# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable wazuh-manager wazuh-indexer wazuh-dashboard
sudo systemctl start wazuh-manager wazuh-indexer wazuh-dashboard

# Configure firewall
sudo ufw allow 1514/tcp
sudo ufw allow 1515/tcp
sudo ufw allow 55000/tcp
sudo ufw allow 9200/tcp
sudo ufw allow 443/tcp

# Check status
sudo systemctl status wazuh-manager wazuh-indexer wazuh-dashboard

# Get server IP
ip addr show | grep 'inet ' | grep -v '127.0.0.1'

echo "Access dashboard at: https://YOUR-SERVER-IP"
echo "Default login: admin/admin"
