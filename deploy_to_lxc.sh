#!/bin/bash

# --- Main Deployment Script for Google Calendar to Telegram Service on Proxmox LXC ---
# This script automates the creation of an LXC container on Proxmox and sets up the
# Google Calendar to Telegram summary service within it.

# --- IMPORTANT PREREQUISITES ---
# 1. SSH access to your Proxmox host with sufficient permissions (root recommended).
# 2. Ensure the LXC template specified in create_lxc_script.sh is available on your Proxmox host.
# 3. Have your `calendar_telegram_service.py`, `requirements.txt`, `credentials.json`,
#    and `token.json` (if already generated) files in the same directory as this script.
# 4. Replace placeholders for TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID in setup_container.sh
#    after the container is created, or pass them securely.

# --- Configuration ---
PROXMOX_HOST="your_proxmox_host_ip_or_hostname" # <<< REPLACE THIS
PROXMOX_USER="root" # Or a user with pct privileges

LXC_IP="192.168.5.157" # Matches the IP in create_lxc_script.sh
LXC_USER="root"
LXC_PASSWORD="Power110$" # Matches the password in create_lxc_script.sh

SERVICE_DIR="/opt/calendar-telegram-service"

# --- Files to transfer ---
SERVICE_FILES=(
  "calendar_telegram_service.py"
  "requirements.txt"
  "setup_container.sh"
  "setup_cron.sh"
  "create_lxc_script.sh"
)

# --- Step 1: Create LXC Container on Proxmox Host ---
echo "\n--- Step 1: Creating LXC Container on Proxmox Host (${PROXMOX_HOST}) ---"

# Transfer the LXC creation script to Proxmox host
echo "Transferring create_lxc_script.sh to ${PROXMOX_HOST}..."
scp create_lxc_script.sh ${PROXMOX_USER}@${PROXMOX_HOST}:/tmp/create_lxc_script.sh
if [ $? -ne 0 ]; then echo "Error: Failed to transfer create_lxc_script.sh"; exit 1; fi

# Execute the LXC creation script on Proxmox host
echo "Executing create_lxc_script.sh on ${PROXMOX_HOST}..."
ssh ${PROXMOX_USER}@${PROXMOX_HOST} "bash /tmp/create_lxc_script.sh"
if [ $? -ne 0 ]; then echo "Error: LXC creation script failed on Proxmox host."; exit 1; fi

echo "Waiting for LXC container to start up (approx. 30 seconds)..."
sleep 30

# --- Step 2: Set up Service Environment inside LXC ---
echo "\n--- Step 2: Setting up Service Environment inside LXC (${LXC_IP}) ---"

# Transfer service files and setup scripts to the LXC container
echo "Transferring service files and setup scripts to LXC container ${LXC_IP}..."
for file in "${SERVICE_FILES[@]}"; do
  if [ "$file" != "create_lxc_script.sh" ]; then # create_lxc_script.sh is for Proxmox host
    scp "$file" ${LXC_USER}@${LXC_IP}:${SERVICE_DIR}/"$file"
    if [ $? -ne 0 ]; then echo "Error: Failed to transfer $file to LXC."; exit 1; fi
  fi
done

# Transfer credentials.json and token.json (if they exist)
if [ -f "credentials.json" ]; then
  echo "Transferring credentials.json to LXC..."
  scp credentials.json ${LXC_USER}@${LXC_IP}:${SERVICE_DIR}/credentials.json
  if [ $? -ne 0 ]; then echo "Warning: Failed to transfer credentials.json to LXC. You may need to do this manually."; fi
else
  echo "credentials.json not found locally. You will need to transfer it manually to ${LXC_IP}:${SERVICE_DIR}/ after setup."
fi

if [ -f "token.json" ]; then
  echo "Transferring token.json to LXC..."
  scp token.json ${LXC_USER}@${LXC_IP}:${SERVICE_DIR}/token.json
  if [ $? -ne 0 ]; then echo "Warning: Failed to transfer token.json to LXC. You may need to do this manually."; fi
else
  echo "token.json not found locally. It will be generated on first run after Google authentication."
fi

# Execute setup_container.sh inside the LXC
echo "Executing setup_container.sh inside LXC ${LXC_IP}..."
ssh ${LXC_USER}@${LXC_IP} "bash ${SERVICE_DIR}/setup_container.sh"
if [ $? -ne 0 ]; then echo "Error: setup_container.sh failed inside LXC."; exit 1; fi

# Execute setup_cron.sh inside the LXC
echo "Executing setup_cron.sh inside LXC ${LXC_IP}..."
ssh ${LXC_USER}@${LXC_IP} "bash ${SERVICE_DIR}/setup_cron.sh"
if [ $? -ne 0 ]; then echo "Error: setup_cron.sh failed inside LXC."; exit 1; fi

echo "\n--- Deployment Complete ---"
echo "The LXC container has been created and the service environment set up."
echo "
--- Next Steps (Manual Intervention Required) ---"
echo "1. **Replace Placeholders:** SSH into the LXC container (ssh ${LXC_USER}@${LXC_IP}) and edit the /etc/environment file to replace `YOUR_TELEGRAM_BOT_TOKEN` and `YOUR_TELEGRAM_CHAT_ID` with your actual values."
echo "   Example: sudo nano /etc/environment"
echo "2. **Google Authentication:** The first time the `calendar_telegram_service.py` script runs (either manually or via cron),
   it will attempt to open a browser for Google OAuth authentication. You will need to complete this step.
   If you transferred `credentials.json` manually, ensure it is in ${SERVICE_DIR}/."
echo "3. **Verify Cron Job:** You can verify the cron job by running: `ssh ${LXC_USER}@${LXC_IP} "crontab -l"`"
echo "4. **Monitor Logs:** Check the service logs at ${SERVICE_DIR}/cron.log for execution details."

echo "Deployment script finished."


