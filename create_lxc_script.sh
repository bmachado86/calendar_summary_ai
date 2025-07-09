#!/bin/bash

# Proxmox LXC Creation Script

# --- Configuration Variables ---
NODE_NAME="pve"
STORAGE="local-lvm"
TEMPLATE="ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
VMID="112"
CONTAINER_NAME="calendar-bot-lxc"
ROOT_PASSWORD="Power110$"
IP_ADDRESS="192.168.5.157/24" # Randomly generated IP
GATEWAY="192.168.5.1"
DNS_SERVER="8.8.8.8"
NUM_CORES="1"
MEMORY_MB="512"
SWAP_MB="512"
DISK_GB="1"

# --- LXC Creation Command ---
# Create the LXC container
# For more options, refer to `man pct create`

echo "Creating LXC container with VMID: $VMID and Name: $CONTAINER_NAME..."

pct create $VMID $STORAGE:vztmpl/$TEMPLATE \
  --hostname $CONTAINER_NAME \
  --password $ROOT_PASSWORD \
  --cores $NUM_CORES \
  --memory $MEMORY_MB \
  --swap $SWAP_MB \
  --rootfs ${STORAGE}:${DISK_GB} \
  --net0 name=eth0,bridge=vmbr0,ip=$IP_ADDRESS,gw=$GATEWAY \
  --nameserver $DNS_SERVER \
  --unprivileged 1 \
  --onboot 1

if [ $? -eq 0 ]; then
  echo "LXC container $CONTAINER_NAME (VMID: $VMID) created successfully."
  echo "Starting LXC container $CONTAINER_NAME (VMID: $VMID)..."
  pct start $VMID
  if [ $? -eq 0 ]; then
    echo "LXC container $CONTAINER_NAME (VMID: $VMID) started successfully."
    echo "You can now access it via SSH: ssh root@${IP_ADDRESS%/*}"
  else
    echo "Failed to start LXC container $CONTAINER_NAME (VMID: $VMID)."
  fi
else
  echo "Failed to create LXC container $CONTAINER_NAME (VMID: $VMID)."
fi

# --- Basic Configuration (Optional, can be done via SSH later) ---
# Example: Update and upgrade packages inside the container
# This part requires the container to be running and accessible.
# You would typically SSH into the container for these steps.
# echo "Waiting for container to fully start..."
# sleep 30 # Give it some time to boot up
# echo "Updating and upgrading packages inside the container..."
# pct exec $VMID -- apt update && apt upgrade -y

echo "LXC creation script finished."


