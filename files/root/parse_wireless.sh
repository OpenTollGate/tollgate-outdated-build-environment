#!/bin/sh

# Create a temporary file for collecting the data
temp_file=$(mktemp)

# Initialize empty JSON object
echo "{}" > "$temp_file"

# Process wireless config and build JSON using jq
while IFS= read -r line; do
    if echo "$line" | grep -q "^config wifi-iface"; then
        # Extract interface name
        iface=$(echo "$line" | grep -o "'.*'" | tr -d "'")
        
        # Get SSID for this interface
        ssid=$(sed -n "/^config wifi-iface '$iface'/,/^config\|$/p" /etc/config/wireless | \
              grep "option ssid" | \
              grep -o "'.*'" | \
              tr -d "'")
        
        # Add to JSON using jq
        cat "$temp_file" | \
        jq --arg iface "$iface" --arg ssid "$ssid" \
        '. + {($iface): $ssid}' > "$temp_file.new" && \
        mv "$temp_file.new" "$temp_file"
    fi
done < /etc/config/wireless

# Format final JSON and save to destination
cat "$temp_file" | jq '.' > "/tmp/wifi_interfaces.json"

# Clean up
rm "$temp_file"

# Display the result
cat /tmp/wifi_interfaces.json
