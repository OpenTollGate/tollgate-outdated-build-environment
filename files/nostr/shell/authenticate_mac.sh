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
mac=$(jq -r '. ^2^ .tags[] | select(. ^0^  == "mac") ^1^ ' "$1")

# Check if MAC address was found
if [ -n "$mac" ]; then
    # Execute ndsctl auth with the MAC address
    ndsctl auth "$mac"
    echo "Authenticated MAC address: $mac"
else
    echo "Error: Could not extract MAC address from file"
    exit 1
fi
