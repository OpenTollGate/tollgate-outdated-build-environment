#!/bin/sh

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install jq using opkg
install_jq_opkg() {
    echo "Updating package lists..."
    opkg update

    echo "Installing jq..."
    opkg install jq

    if ! command_exists jq; then
        echo "Failed to install jq."
        exit 1
    fi
}

# Function to install jq using apt-get
install_jq_apt() {
    echo "Updating package lists..."
    sudo apt-get update

    echo "Installing jq..."
    sudo apt-get install -y jq

    if ! command_exists jq; then
        echo "Failed to install jq."
        exit 1
    fi
}

# Detect if the system is OpenWRT or Debian-based
if [ -f /etc/openwrt_release ]; then
    # System is OpenWRT
    PACKAGE_MANAGER="opkg"
elif [ -f /etc/debian_version ]; then
    # System is Debian-based
    PACKAGE_MANAGER="apt-get"
else
    echo "Unsupported system."
    exit 1
fi

# Check if jq is installed
if ! command_exists jq; then
    if [ "$PACKAGE_MANAGER" = "opkg" ]; then
        # Install jq using opkg
        if command_exists opkg; then
            install_jq_opkg
        else
            echo "opkg is not available on this system."
            exit 1
        fi
    elif [ "$PACKAGE_MANAGER" = "apt-get" ]; then
        # Install jq using apt-get
        if command_exists apt-get; then
            install_jq_apt
        else
            echo "apt-get is not available on this system."
            exit 1
        fi
    fi
fi

