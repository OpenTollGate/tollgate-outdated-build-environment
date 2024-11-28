#!/bin/sh

relay=$1
purser=$2

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Please provide relay and purser as arguemnts"
    exit 1
fi


echo "Relay: $relay"
echo "Purser: $purser"
# wss://tollbooth.stens.dev a057f743eca9efe9c97e6358bf2b37b05349029edfaa1a5e6e0c117fc95b9114

# Get the latest authorization event
auth_event=$(./get_latest_authorize.sh $relay $purser)

# Check if auth_event is empty
if [ -z "$auth_event" ]; then
    echo "Error: No authorization event received"
    exit 1
fi

# Calculate SHA256 checksum of the event
checksum=$(echo "$auth_event" | sha256sum | cut -d' ' -f1)

# Define filename
filename="/tmp/kind66666_${checksum}"

# Check if file exists
if [ ! -f "$filename" ]; then
    # Store the event in the file
    printf '%s\n' "$auth_event" > "$filename"
    echo "Stored new event in $filename"

    ./authenticate_mac.sh $filename
    
else
    echo "Event already processed (file $filename exists)"
    exit 0
fi
