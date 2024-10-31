#!/bin/bash

# Define the IP addresses of the routers
ROUTER1_IP="192.168.8.1"
ROUTER2_IP="192.168.21.1"

# Define the directories to copy from each router
ROUTER1_DIR="router1_config"
ROUTER2_DIR="router2_config"

# Define the list of relevant files to copy
FILES_TO_COPY=(
    "/etc/config/network"
    "/etc/config/firewall"
    "/etc/config/uhttpd"
    "/etc/config/dhcp"
    "/etc/config/system"
    "/etc/config/wireless"
    "/etc/firewall.user"
    "/etc/sysctl.conf"
    "/etc/hosts"
    "/etc/resolv.conf"
)

# Create directories to store copied files
mkdir -p $ROUTER1_DIR
mkdir -p $ROUTER2_DIR

# Function to copy files from a router
copy_files() {
    local router_ip=$1
    local dest_dir=$2

    for file in "${FILES_TO_COPY[@]}"; do
        scp root@$router_ip:$file $dest_dir/
    done
}

# Copy files from both routers
copy_files $ROUTER1_IP $ROUTER1_DIR
copy_files $ROUTER2_IP $ROUTER2_DIR

echo "Configuration files copied. You can compare the files in $ROUTER1_DIR and $ROUTER2_DIR."
