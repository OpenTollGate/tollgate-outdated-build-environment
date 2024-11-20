#!/bin/sh

# Check if URL argument is provided
if [ -z "$1" ]; then
    echo "Error: Please provide firmware URL"
    echo "Usage: $0 <firmware_url>"
    exit 1
fi

FIRMWARE_URL="$1"
FIRMWARE_PATH="/tmp/firmware_upgrade.bin"
MELT_SCRIPT="/root/melt_change.sh"
CHANGE_FILE="/root/changeTokens.json"

# Check if melt_change.sh exists
if [ ! -f "$MELT_SCRIPT" ]; then
    echo "Error: $MELT_SCRIPT not found"
    exit 1
fi

# Check if changeTokens.json exists and has tokens
if [ -f "$CHANGE_FILE" ]; then
    TOKEN_COUNT=$(jq '.tokens | length' "$CHANGE_FILE")
    if [ "$TOKEN_COUNT" -gt 0 ]; then
        echo "Found $TOKEN_COUNT tokens to melt before upgrade"
        
        # Attempt to melt all change
        if ! $MELT_SCRIPT -u user-86f52; then
            echo "Error: Failed to melt all change tokens"
            exit 1
        fi
        
        # Verify all tokens were melted
        if [ -f "$CHANGE_FILE" ]; then
            REMAINING_TOKENS=$(jq '.tokens | length' "$CHANGE_FILE")
            if [ "$REMAINING_TOKENS" -gt 0 ]; then
                echo "Error: $REMAINING_TOKENS tokens remain unmelted"
                exit 1
            fi
        fi
    else
        echo "No tokens found in $CHANGE_FILE"
    fi
else
    echo "No change file found, proceeding with upgrade"
fi

# Download firmware
echo "Downloading firmware from $FIRMWARE_URL"
if ! wget -O "$FIRMWARE_PATH" "$FIRMWARE_URL"; then
    echo "Error: Failed to download firmware"
    exit 1
fi

# Verify file was downloaded
if [ ! -f "$FIRMWARE_PATH" ]; then
    echo "Error: Firmware file not found at $FIRMWARE_PATH"
    exit 1
fi

echo "All checks passed. Proceeding with firmware upgrade..."
echo "Warning: System will reboot after upgrade"
sleep 5

# Perform upgrade
sysupgrade -n "$FIRMWARE_PATH"
