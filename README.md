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
