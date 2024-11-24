#!/bin/sh

# Function to find wireless interface
get_wifi_interface() {
    # Get the first wireless interface name from UCI config
    uci show wireless | grep "wifi-iface" | head -n1 | cut -d. -f1-2
}

# Get wireless interface
WIFI_IF=$(get_wifi_interface)

if [ -z "$WIFI_IF" ]; then
    echo "Error: No wireless interface found"
    exit 1
fi

echo "Using wireless interface: $WIFI_IF"

# Show usage if no arguments provided
usage() {
    echo "Usage: $0 <OUI> <TYPE>"
    echo "Example: $0 000000 01"
    echo "  OUI: 6-digit hex Organization Unique Identifier"
    echo "  TYPE: 2-digit hex message type"
    echo "Price will be automatically read from /tmp/moscow_time.json"
    exit 1
}

# Check if we have the right number of arguments
if [ $# -ne 2 ]; then
    usage
fi

# Get arguments
OUI="$1"
TYPE="$2"

# Read price from JSON file
if [ ! -f "/tmp/moscow_time.json" ]; then
    echo "Error: /tmp/moscow_time.json not found"
    exit 1
fi

PRICE_SATS=$(jq -r '.sats_per_dollar' /tmp/moscow_time.json | awk '{printf "%.0f", $1}')

if [ -z "$PRICE_SATS" ] || [ "$PRICE_SATS" = "null" ]; then
    echo "Error: Failed to read sats_per_dollar from JSON file"
    exit 1
fi

# Validate inputs
if ! echo "$OUI" | grep -Eq '^[0-9A-Fa-f]{6}$'; then
    echo "Error: OUI must be 6 hex digits"
    usage
fi

if ! echo "$TYPE" | grep -Eq '^[0-9A-Fa-f]{2}$'; then
    echo "Error: TYPE must be 2 hex digits"
    usage
fi

if ! echo "$PRICE_SATS" | grep -Eq '^[0-9]+$'; then
    echo "Error: Failed to get valid PRICE_SATS value"
    usage
fi

# Function to convert decimal to 8-byte hex with leading zeros
dec2hex() {
    printf "%08x" "$1"
}

# Function to calculate length of payload in hex (2 digits)
calc_length() {
    # 3 bytes OUI + 1 byte type + length of data in bytes
    total_bytes=$((3 + 1 + $(echo -n "$1" | wc -c) / 2))
    printf "%02x" "$total_bytes"
}

# Convert price to hex
price_hex=$(dec2hex $PRICE_SATS)

# Construct data payload
payload="${OUI}${TYPE}${price_hex}"

# Calculate length
length=$(calc_length "$payload")

# Construct final vendor elements string
vendor_elements="dd${length}${payload}"

# Set the wireless config
uci set ${WIFI_IF}.vendor_elements="$vendor_elements"
uci commit wireless
wifi reload

# Print for verification
echo "Price set to $PRICE_SATS satoshis"
echo "Vendor elements string: $vendor_elements"

