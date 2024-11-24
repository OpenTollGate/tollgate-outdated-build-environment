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

# Apply settings
uci set ${WIFI_IF}.ieee80211u=1
uci set ${WIFI_IF}.interworking=1
uci set ${WIFI_IF}.access_network_type=2
uci set ${WIFI_IF}.internet=1
uci set ${WIFI_IF}.asra=1
uci set ${WIFI_IF}.esr=0
uci set ${WIFI_IF}.uesa=0

# Commit changes and reload
uci commit wireless
wifi reload

echo "802.11u settings applied successfully"
