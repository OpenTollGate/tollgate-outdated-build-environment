#!/bin/sh

# Function to run the network selection script
select_network() {
    ./sort_wifi_networks.sh --select-ssid
}

# Function to check internet connectivity
check_internet() {
    # Try to ping a reliable host (Google DNS)
    ping -c 3 8.8.8.8 > /dev/null 2>&1
    return $?
}

# Run the network selection script and check if it succeeded
select_network

if [ $? -ne 0 ]; then
    echo "Failed to select a network or retrieve the connection details."
    exit 1
fi

# Read the selected network JSON from the file
network_json=$(cat /tmp/selected_ssid.md)

if [ -z "$network_json" ]; then
    echo "Failed to read the selected network details from /tmp/selected_ssid.md."
    exit 1
fi

# Parse SSID and encryption type from the network JSON
NEW_SSID=$(echo "$network_json" | jq -r '.ssid')
ENCRYPTION_TYPE=$(echo "$network_json" | jq -r '.encryption' | tr '[:upper:]' '[:lower:]')

# Check if we successfully parsed the SSID and encryption type
if [ -z "$NEW_SSID" ] || [ -z "$ENCRYPTION_TYPE" ]; then
    echo "Failed to parse SSID or encryption type from the selected network details."
    exit 1
fi

# Only prompt for password if not a TollGate network
if ! echo "$NEW_SSID" | grep -q "^TollGate_"; then
    echo "Enter the password for SSID '$NEW_SSID':"
    read -s NEW_PASSWORD
fi

get_wifi_interface() {
    # This will get the first managed mode interface
    iw dev | awk '$1 == "Interface" {iface=$2} $1 == "type" && $2 == "managed" {print iface; exit}'
}

# Update firewall configuration
uci set firewall.@zone[1].network='wan wan6 wwan'

# Update network configuration
uci set network.wwan=interface
uci set network.wwan.proto='dhcp'

# Update wireless configuration
uci set wireless.radio0.disabled='0'
uci set wireless.radio0.cell_density='0'
# uci set wireless.default_radio0.disabled='1'  # Initially disable AP

# Remove existing wifinet1 configuration if it exists
uci delete wireless.wifinet1

# Create a new wifi-iface section named 'wifinet1'
uci set wireless.wifinet1=wifi-iface
uci set wireless.wifinet1.device='radio0'
uci set wireless.wifinet1.mode='sta'
uci set wireless.wifinet1.network='wwan'
uci set wireless.wifinet1.ssid=''"$NEW_SSID"''

# Check if this is a TollGate network
if echo "$NEW_SSID" | grep -q "^TollGate_"; then
    # Force encryption to none for TollGate networks
    uci set wireless.wifinet1.encryption='none'
else
    # Set encryption based on the parsed type for non-TollGate networks
    case "$ENCRYPTION_TYPE" in
        sae)
            uci set wireless.wifinet1.encryption='sae'
            ;;
        wpa2 | psk2)
            uci set wireless.wifinet1.encryption='psk2'
            ;;
        none)
            uci set wireless.wifinet1.encryption='none'
            ;;
        *)
            echo "Unknown encryption type '$ENCRYPTION_TYPE'. Using 'psk-mixed' as fallback."
            uci set wireless.wifinet1.encryption='psk-mixed'
            ;;
    esac

    # Only set password for non-TollGate networks
    if [ -n "$NEW_PASSWORD" ]; then
        uci set wireless.wifinet1.key="$NEW_PASSWORD"
    fi
fi

# Commit the changes
uci commit firewall
uci commit network
uci commit wireless

# Restart the network to apply changes
/etc/init.d/network restart

# Check if the changes were made successfully
if [ $? -eq 0 ]; then
    # Display the updated wireless configuration
    echo "Wireless configuration updated successfully."
    echo "New SSID: $NEW_SSID"

    # Mask the password with asterisks
    PASSWORD_LENGTH=${#NEW_PASSWORD}
    MASKED_PASSWORD=$(printf '%*s' "$PASSWORD_LENGTH" | tr ' ' '*')

    echo "New PASSWORD: $MASKED_PASSWORD"
    echo "Detected Encryption: $ENCRYPTION_TYPE"

    # Wait for network to stabilize
    echo "Waiting for network connection (30 seconds max)..."
    for i in $(seq 1 30); do
        if ip route | grep -q default; then
            # Get the gateway IP
            GATEWAY_IP=$(ip route | grep default | awk '{print $3}')
            if [ -n "$GATEWAY_IP" ]; then
                echo "Gateway IP detected: $GATEWAY_IP"
                
                # Check internet connectivity
                if check_internet; then
                    echo "Internet connectivity confirmed. Enabling AP..."
		    /root/./get_moscow_time.sh
                    # Enable the AP
                    uci set wireless.default_radio0.disabled='0'
                    uci commit wireless
                    wifi reload
                    echo "Access Point has been enabled."
                else
                    echo "No internet connectivity detected. AP remains disabled."
                fi

                # If this is a TollGate network, update /etc/hosts
                if echo "$NEW_SSID" | grep -q "^TollGate_"; then
                    # Update /etc/hosts - remove existing status.client entry if it exists
                    sed -i '/status.client/d' /etc/hosts
                    # Add new entry
                    echo "$GATEWAY_IP status.client" >> /etc/hosts
                    echo "Updated /etc/hosts with gateway IP mapping"
                fi
                break
            fi
        fi
        sleep 1
    done
else
    echo "Error: Failed to update the wireless configuration."
    exit 1
fi
