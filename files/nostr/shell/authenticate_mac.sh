#!/bin/sh

# Check if a filename was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <kind66666_file>"
    exit 1
fi

# Check if file exists
if [ ! -f "$1" ]; then
    echo "Error: File $1 does not exist"
    exit 1
fi

# Read the file content and extract MAC address using jq
mac=$(jq -r '.tags[] | select(.[0] == "mac") [1] ' "$1")
end_time=$(jq -r '.tags[] | select(.[0] == "session-end") [1] ' "$1")

# Check if MAC address was found
if [ -n "$mac" ]; then
    # Execute ndsctl auth with the MAC address
    # Get current unix timestamp
    now=$(date +%s)
    # Calculate duration
    duration=$((end_time - now))
    duration_minutes=$(( ($duration / 60) + ($duration % 60 > 0) ))

    echo "now: $now" >> /tmp/nostr_autenticate.md
    echo "end_time: $end_time" >> /tmp/nostr_autenticate.md
    echo "duration: $duration" >> /tmp/nostr_autenticate.md
    # Authorize with calculated duration
    if [ $duration -lt 0 ]; then
	echo "Duration must be a postive number" >> /tmp/nostr_autenticate.md
    elif [ $duration -lt 60 ]; then
	echo "Duration must be atleast a minute!" >> /tmp/nostr_autenticate.md
	ndsctl auth "74:a6:cd:cc:ef:e0" 1
    else
	ndsctl auth "74:a6:cd:cc:ef:e0" $duration
    fi
	
    echo "Authenticated MAC address: $mac" >> /tmp/nostr_autenticate.md
else
    echo "Error: Could not extract MAC address from file" >> /tmp/nostr_autenticate.md
    exit 1
fi
