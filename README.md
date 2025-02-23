# Proxmox Auto Update Script

This repository contains a Bash script designed to automatically update your Proxmox host node and all running LXC containers (with the exception of container ID 210). The script logs the update process and provides a summary of the number of packages upgraded on both the node and each container.

## Overview

The script performs the following tasks:
- **Node Update:** Runs `apt update` and `apt upgrade -y` on the Proxmox host.
- **Container Update:** Iterates over all LXC containers on the node, checks if each container is running, and then runs the update commands inside each container.
- **Exclusion:** Skips the update for container ID 210.
- **Logging:** Records the update process, including the number of packages upgraded, to `/var/log/lxc-update.log`.
- **Root Check:** Ensures that the script is run as root to prevent permission issues during package updates.

## Features

- **Comprehensive Updating:** Updates both the Proxmox host node and its containers.
- **Selective Execution:** Skips containers that are not running and specifically excludes container ID 210.
- **Enhanced Logging:** Uses `tee` for real-time console output while appending details to a log file.
- **Robust Parsing:** Extracts the number of upgraded packages using a more resilient pattern matching technique.
- **Root Privilege Enforcement:** The script checks that it is run as root, ensuring all update commands execute successfully.

## Prerequisites

- A Proxmox server with LXC containers configured.
- The host and containers must be using APT as the package management system.
- Sufficient privileges (root) to execute update and upgrade commands.

## Installation

1. **Clone the Repository or Create the Script File:**

   You can either clone this repository or create the script manually. To create it manually, log into your Proxmox server and create a new file:

   ```bash
   nano /usr/local/bin/lxc-update.sh
   ```

2. **Copy the below script if using nano:**

  ```bash
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
```

3. **Make the Script Executable**

Change the permissions of the script to allow execution:

```bash
chmod +x /usr/local/bin/lxc-update.sh
```

4. **Test the Script**

After making the script executable, run it manually to ensure it works correctly:

```bash
/usr/local/bin/lxc-update.sh
```

## Usage

### Manual Execution

Run the script directly from the command line with root privileges:

```bash
sudo /usr/local/bin/lxc-update.sh
```

### Scheduling with Cron

To automate the update process, you can schedule the script to run at regular intervals using cron.

1. **Open the root user's crontab:**

   ```bash
   crontab -e
   ```

2. **Add the following line to run the script daily at 3:00 AM:**

   ```bash
   0 3 * * * /usr/local/bin/lxc-update.sh
   ```

2. **Save and exit the editor.**

The script will now run automatically at the scheduled time, ensuring your Proxmox node and containers are regularly updated.

## License

This project is licensed under the [MIT License](LICENSE).

## Contributing

Contributions are welcome! Please feel free to fork the repository, open issues, and submit pull requests with improvements, bug fixes, or new features. For significant changes, consider opening an issue first to discuss your ideas and ensure alignment with the project's goals.

## Disclaimer

Use this script at your own risk. The authors are not responsible for any damage or data loss that may occur as a result of using this script. Always test in a non-production environment before deploying to live systems.

