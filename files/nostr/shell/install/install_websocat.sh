#!/bin/sh

# Define URLs and file paths
WEBSOCAT_BIN="websocat"
EXPECTED_WEBSOCAT_VERSION="1.13.0"
TMP_DIR="/tmp"

# Ensure opkg is using /tmp as a valid destination
if ! grep -q "dest tmp /tmp" /etc/opkg.conf; then
    echo "Adding 'dest tmp /tmp' to /etc/opkg.conf"
    echo "dest tmp /tmp" >> /etc/opkg.conf
fi

# Check if Websocat is installed and if the version matches
if [ -x "$TMP_DIR/$WEBSOCAT_BIN" ]; then
    INSTALLED_VERSION=$($TMP_DIR/$WEBSOCAT_BIN --version | awk '{print $2}')
    if [ "$INSTALLED_VERSION" = "$EXPECTED_WEBSOCAT_VERSION" ]; then
        echo "Correct version of Websocat is already installed."
        exit 0
    else
        echo "Installed Websocat version: $INSTALLED_VERSION"
        echo "Websocat version mismatch. Installing correct version..."
    fi
else
    echo "Websocat is not installed. Installing..."
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" > /dev/null 2>&1
}

# Function to update package lists if not updated today
update_package_lists_if_needed() {
    update_marker="/var/lib/opkg/status"

    if [ ! -f "$update_marker" ] || [ "$(date +%Y-%m-%d -r "$update_marker")" != "$(date +%Y-%m-%d)" ]; then
        echo "Running opkg update..."
        opkg update
    else
        echo "opkg update has already been run today."
    fi
}

# Function to install Websocat
install_websocat() {
    echo "Installing websocat using opkg..."
    opkg --dest tmp install websocat

    if [ $? -eq 0 ]; then
        echo "Websocat installed/updated successfully at /tmp/websocat."
    else
        echo "Failed to install websocat."
        exit 1
    fi
}

# Main execution flow
update_package_lists_if_needed
install_websocat

echo "Websocat setup complete."

