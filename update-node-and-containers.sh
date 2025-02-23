#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

# Log file for update output
LOGFILE="/var/log/lxc-update.log"

# Start logging
echo "Starting updates for node and containers: $(date)" >> "$LOGFILE"
echo "------------------------------------------" >> "$LOGFILE"

# Step 1: Update the Proxmox node (pve1)
echo "Updating Proxmox node (pve1)..." | tee -a "$LOGFILE"
NODE_OUTPUT=$(apt update && apt upgrade -y)
# Extract the number from the summary line that contains "upgraded"
NODE_UPGRADED=$(echo "$NODE_OUTPUT" | grep -Eo '[0-9]+ upgraded' | head -n1 | awk '{print $1}')
NODE_UPGRADED=${NODE_UPGRADED:-0}
echo "Proxmox node: $NODE_UPGRADED packages upgraded." | tee -a "$LOGFILE"
echo "------------------------------------------" | tee -a "$LOGFILE"

# Step 2: Get a list of all LXC container IDs
CONTAINERS=$(pct list | awk 'NR>1 {print $1}')

# Loop through each container and perform updates
for CTID in $CONTAINERS; do
    # Exclude container ID 210
    if [ "$CTID" -eq 210 ]; then
        echo "Skipping container $CTID (excluded)." | tee -a "$LOGFILE"
        continue
    fi

    echo "Updating container ID: $CTID" | tee -a "$LOGFILE"
    
    # Check if the container is running
    if pct status "$CTID" | grep -q "status: running"; then
        # Run apt update and upgrade within the container
        OUTPUT=$(pct exec "$CTID" -- bash -c "apt update && apt upgrade -y")
        
        # Extract the number of packages upgraded from the container output robustly
        UPGRADED=$(echo "$OUTPUT" | grep -Eo '[0-9]+ upgraded' | head -n1 | awk '{print $1}')
        UPGRADED=${UPGRADED:-0}
        
        echo "Container $CTID: $UPGRADED packages upgraded." | tee -a "$LOGFILE"
    else
        echo "Container $CTID is not running. Skipping." | tee -a "$LOGFILE"
    fi
    
    echo "------------------------------------------" | tee -a "$LOGFILE"
done

echo "All updates completed: $(date)" >> "$LOGFILE"
