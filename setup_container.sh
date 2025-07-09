#!/bin/bash

# --- Container Setup Script ---
# This script is intended to be run inside the LXC container.

SERVICE_DIR="/opt/calendar-telegram-service"

echo "Updating and upgrading packages..."
apt update && apt upgrade -y

echo "Installing Python3 and pip..."
apt install -y python3 python3-pip

echo "Creating service directory: $SERVICE_DIR..."
mkdir -p $SERVICE_DIR
cd $SERVICE_DIR

echo "--- IMPORTANT: File Transfer Instructions ---"
echo "Before running this script inside the LXC, you MUST transfer the following files from your local machine to this directory ($SERVICE_DIR) in the LXC:"
echo "- calendar_telegram_service.py"
echo "- requirements.txt"
echo "- credentials.json (from Google Cloud Console - keep this file secure!)"
echo "- token.json (generated after first Google authentication - keep this file secure!)"
echo "You can use `scp` from your Proxmox host or local machine, for example:"
echo "  scp /path/to/your/calendar_telegram_service.py root@<LXC_IP>:$SERVICE_DIR/"
echo "  scp /path/to/your/requirements.txt root@<LXC_IP>:$SERVICE_DIR/"
echo "  scp /path/to/your/credentials.json root@<LXC_IP>:$SERVICE_DIR/"
echo "  scp /path/to/your/token.json root@<LXC_IP>:$SERVICE_DIR/ (if already generated)"
echo "----------------------------------------------"

# Install Python dependencies
echo "Installing Python dependencies from requirements.txt..."
pip3 install -r requirements.txt

# Set up environment variables
echo "Setting up environment variables for Telegram Bot Token and Chat ID..."
echo "These will be stored in /etc/environment for system-wide access."

# It is crucial to replace YOUR_TELEGRAM_BOT_TOKEN and YOUR_TELEGRAM_CHAT_ID
# with your actual values. For better security, consider using a secrets management
# solution or passing these as secure environment variables during deployment.

# Append to /etc/environment (requires root privileges)
# This makes the variables available to all processes, including cron jobs.

# IMPORTANT: Replace the placeholder values below with your actual Telegram Bot Token and Chat ID.
# You can edit this file directly on the LXC or pass these values during the setup process.

cat << EOF >> /etc/environment
TELEGRAM_BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID="YOUR_TELEGRAM_CHAT_ID"
EOF

echo "Environment variables setup complete. Remember to replace placeholders."

echo "Container setup script finished."


