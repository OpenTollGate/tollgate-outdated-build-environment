#!/bin/sh

# Create a temporary file for collecting the data
temp_file=$(mktemp)

# Initialize empty JSON object
echo "{}" > "$temp_file"

# Get list of all wireless interfaces
for iface in $(uci show wireless | grep "=wifi-iface" | cut -d. -f2 | cut -d= -f1); do
    # Get SSID for this interface using UCI
    ssid=$(uci get wireless.$iface.ssid)
    
    # Add to JSON using jq
    cat "$temp_file" | \
    jq --arg iface "$iface" --arg ssid "$ssid" \
    '. + {($iface): $ssid}' > "$temp_file.new" && \
    mv "$temp_file.new" "$temp_file"
done

# Format final JSON and save to destination
cat "$temp_file" | jq '.' > "/tmp/wifi_interfaces.json"

# Clean up
rm "$temp_file"

# Display the result
cat /tmp/wifi_interfaces.json
