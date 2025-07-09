# Google Calendar to Telegram Service Deployment on Proxmox LXC

This document provides comprehensive instructions and scripts to deploy the Google Calendar to Telegram daily summary service within a Proxmox LXC container.

## Overview

The deployment process is automated through a main script (`deploy_to_lxc.sh`) that orchestrates the following:

1.  **LXC Container Creation:** Creates a new Ubuntu 24.04 LXC container on your Proxmox host.
2.  **Container Setup:** Installs necessary Python dependencies and prepares the environment inside the LXC.
3.  **Service File Transfer:** Transfers the Python service script and its dependencies to the LXC.
4.  **Environment Variable Configuration:** Sets up environment variables for your Telegram Bot Token and Chat ID.
5.  **Cron Job Setup:** Configures a daily cron job to run the calendar summary service at 9 AM.

## Prerequisites

Before you begin, ensure you have the following:

*   **Proxmox Host:** Access to a Proxmox VE server.
*   **SSH Access:** SSH access to your Proxmox host with a user that has privileges to create and manage LXC containers (e.g., `root`).
*   **LXC Template:** The `ubuntu-24.04-standard_24.04-2_amd64.tar.zst` template available on your Proxmox host. You can download it from the Proxmox UI under `local` -> `Content` -> `Templates`.
*   **Service Files:** The following files from the previously generated service in the same directory as `deploy_to_lxc.sh`:
    *   `calendar_telegram_service.py`
    *   `requirements.txt`
    *   `credentials.json` (from your Google Cloud Console - **keep this file secure!**)
    *   `token.json` (this file is generated after the first successful Google authentication; if you don't have it yet, it will be created on the first run)
*   **Telegram Bot Token and Chat ID:** Your Telegram bot token obtained from BotFather and your Telegram chat ID. These will be configured inside the LXC.

## Deployment Steps

Follow these steps to deploy the service:

### Step 1: Prepare the Deployment Files

1.  Download all the provided script files (`deploy_to_lxc.sh`, `create_lxc_script.sh`, `setup_container.sh`, `setup_cron.sh`).
2.  Ensure you have `calendar_telegram_service.py`, `requirements.txt`, `credentials.json`, and `token.json` (if available) in the same directory as the deployment scripts.

### Step 2: Configure the Main Deployment Script

1.  Open `deploy_to_lxc.sh` in a text editor.
2.  **Replace `your_proxmox_host_ip_or_hostname`** with the actual IP address or hostname of your Proxmox server.
    ```bash
    PROXMOX_HOST="your_proxmox_host_ip_or_hostname" # <<< REPLACE THIS
    ```
    The `PROXMOX_USER` is set to `root` by default, which is recommended for `pct` commands. If you use a different user, ensure it has the necessary permissions.

### Step 3: Execute the Deployment Script

1.  Open your local terminal or SSH client.
2.  Navigate to the directory where you saved all the deployment files.
3.  Make the main deployment script executable:
    ```bash
    chmod +x deploy_to_lxc.sh
    ```
4.  Run the deployment script:
    ```bash
    ./deploy_to_lxc.sh
    ```

    The script will prompt you for your Proxmox host's SSH password (if not using SSH keys) and then for the LXC container's root password (`Power110$`).

    **What the script does:**
    *   Transfers `create_lxc_script.sh` to your Proxmox host and executes it to create and start the LXC container.
    *   Waits for the LXC container to boot up.
    *   Transfers `calendar_telegram_service.py`, `requirements.txt`, `setup_container.sh`, `setup_cron.sh`, `credentials.json`, and `token.json` (if present) to the newly created LXC container.
    *   Executes `setup_container.sh` inside the LXC to install Python, pip, and other dependencies, and sets up placeholder environment variables for Telegram.
    *   Executes `setup_cron.sh` inside the LXC to configure the daily cron job.

### Step 4: Post-Deployment Configuration (Manual Intervention Required)

After the `deploy_to_lxc.sh` script completes, you **must** perform the following manual steps:

1.  **SSH into the LXC Container:**
    ```bash
    ssh root@192.168.5.157 # Use the IP address assigned to your LXC
    ```
    The password is `Power110$`.

2.  **Replace Telegram Environment Variable Placeholders:**
    The `setup_container.sh` script adds placeholder environment variables to `/etc/environment`. You need to replace these with your actual Telegram Bot Token and Chat ID.
    ```bash
    sudo nano /etc/environment
    ```
    Find and modify the lines:
    ```
    TELEGRAM_BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
    TELEGRAM_CHAT_ID="YOUR_TELEGRAM_CHAT_ID"
    ```
    Replace `YOUR_TELEGRAM_BOT_TOKEN` and `YOUR_TELEGRAM_CHAT_ID` with your actual values. Save and exit the file.

3.  **Reload Environment Variables:**
    For the changes to `/etc/environment` to take effect, you might need to reboot the LXC or source the file (though reboot is more reliable for cron jobs):
    ```bash
    sudo reboot
    ```

4.  **Google OAuth Authentication (First Run):**
    The first time the `calendar_telegram_service.py` script runs (either manually or via the cron job), it will attempt to open a browser for Google OAuth authentication. Since the LXC is headless, you will need to perform this step manually from a machine with a web browser.

    To trigger this manually and complete the authentication:
    *   SSH into the LXC container.
    *   Navigate to the service directory:
        ```bash
        cd /opt/calendar-telegram-service
        ```
    *   Run the service script:
        ```bash
        python3 calendar_telegram_service.py
        ```
    *   The script will output a URL. Copy this URL and paste it into your web browser on your local machine. Follow the Google authentication prompts. Once authorized, it will provide a verification code. Copy this code back to your LXC terminal where the script is running.
    *   A `token.json` file will be generated in `/opt/calendar-telegram-service/`. This file stores your Google API credentials securely for future runs.

### Step 5: Verify Deployment

1.  **Check Cron Job:**
    To verify that the cron job is correctly set up inside the LXC, SSH into the LXC and run:
    ```bash
    crontab -l
    ```
    You should see a line similar to:
    ```
    0 9 * * * /usr/bin/python3 /opt/calendar-telegram-service/calendar_telegram_service.py >> /opt/calendar-telegram-service/cron.log 2>&1
    ```

2.  **Monitor Logs:**
    The service will log its output to `/opt/calendar-telegram-service/cron.log`. You can monitor this file for execution details and any errors:
    ```bash
    tail -f /opt/calendar-telegram-service/cron.log
    ```

## Troubleshooting

*   **LXC Creation Issues:** If the LXC creation fails, check the `create_lxc_script.sh` for correct parameters (template name, storage, etc.) and ensure your Proxmox user has the necessary permissions.
*   **SSH Connection Issues:** Verify the IP address of the LXC and ensure SSH is running on the container. Check firewall rules on both Proxmox and the LXC.
*   **Python Dependencies:** If the service fails to run, ensure all Python dependencies are installed. You can manually run `pip3 install -r requirements.txt` inside the LXC.
*   **Environment Variables:** Double-check that `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` are correctly set in `/etc/environment` inside the LXC.
*   **Google Authentication:** Ensure `credentials.json` is in the correct directory and that you have completed the OAuth flow successfully, resulting in a `token.json` file.

## File Structure

Your local deployment directory should contain:

```
./
├── deploy_to_lxc.sh
├── create_lxc_script.sh
├── setup_container.sh
├── setup_cron.sh
├── calendar_telegram_service.py
├── requirements.txt
├── credentials.json
└── token.json (optional, will be generated)
```

Inside the LXC container, the service files will be located at `/opt/calendar-telegram-service/`.

---
*Generated by Manus AI*


