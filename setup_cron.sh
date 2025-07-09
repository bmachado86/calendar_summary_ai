#!/bin/bash

# --- Cron Job Setup Script ---
# This script is intended to be run inside the LXC container.

SERVICE_DIR="/opt/calendar-telegram-service"
SERVICE_SCRIPT="calendar_telegram_service.py"

echo "Setting up daily cron job for calendar summary service..."

# Add cron job to run the script daily at 9 AM
# The cron job will execute the Python script using the full path to python3
# and the service script.

# Ensure the script is executable
chmod +x ${SERVICE_DIR}/${SERVICE_SCRIPT}

# Add the cron job. We use a temporary file to add the cron job safely.
(crontab -l 2>/dev/null; echo "0 9 * * * /usr/bin/python3 ${SERVICE_DIR}/${SERVICE_SCRIPT} >> ${SERVICE_DIR}/cron.log 2>&1") | crontab -

if [ $? -eq 0 ]; then
  echo "Cron job added successfully. The service will run daily at 9 AM."
  echo "You can check the cron log at ${SERVICE_DIR}/cron.log for execution details."
else
  echo "Failed to add cron job."
fi

echo "Cron job setup script finished."


