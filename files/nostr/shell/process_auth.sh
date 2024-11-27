#!/bin/sh

# Get the latest authorization event
auth_event=$(./get_latest_authorize.sh wss://tollbooth.stens.dev a057f743eca9efe9c97e6358bf2b37b05349029edfaa1a5e6e0c117fc95b9114)

# Check if auth_event is empty
if [ -z "$auth_event" ]; then
    echo "Error: No authorization event received"
    exit 1
fi

# Calculate SHA256 checksum of the event
checksum=$(echo "$auth_event" | sha256sum | cut -d' ' -f1)

# Define filename
filename="kind66666_${checksum}"

# Check if file exists
if [ ! -f "$filename" ]; then
    # Store the event in the file
    printf '%s\n' "$auth_event" > "$filename"
    echo "Stored new event in $filename"
    
    # Extract MAC address from the event using jq
    mac=$(echo "$auth_event" | jq -r '. ^2^ .tags[] | select(. ^0^  == "mac") ^1^ ')
    
    if [ ! -z "$mac" ]; then
        # Execute ndsctl auth with the MAC address
        ndsctl auth "$mac"
        echo "Authenticated MAC address: $mac"
    else
        echo "Error: Could not extract MAC address from event"
        exit 1
    fi
else
    echo "Event already processed (file $filename exists)"
    exit 0
fi
