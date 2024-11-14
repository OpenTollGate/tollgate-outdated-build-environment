#!/bin/sh

# Function to extract SSIDs and interface names
parse_wireless_config() {
    # Create a temporary file for building the JSON
    local temp_file="/tmp/wifi_map.json"
    echo "{" > "$temp_file"
    
    local first_entry=1
    
    # Process each wifi-iface section
    while IFS= read -r line; do
        if echo "$line" | grep -q "^config wifi-iface '"; then
            # Extract interface name
            iface=$(echo "$line" | sed "s/config wifi-iface '$.*$'/\1/")
            # Get the SSID for this interface
            ssid=$(sed -n "/^config wifi-iface '$iface'/,/^config\|$/p" /etc/config/wireless | \
                  grep "option ssid" | \
                  sed "s/.*option ssid '$.*$'/\1/")
            
            # Add comma if not first entry
            if [ "$first_entry" -eq 0 ]; then
                echo "," >> "$temp_file"
            fi
            first_entry=0
            
            # Add entry to JSON
            echo "    \"$iface\": \"$ssid\"" >> "$temp_file"
        fi
    done < /etc/config/wireless
    
    echo "}" >> "$temp_file"
    
    # Move temp file to final location
    mv "$temp_file" "/tmp/wifi_interfaces.json"
}

# Execute the function
parse_wireless_config

# Optional: Display the result
cat /tmp/wifi_interfaces.json
