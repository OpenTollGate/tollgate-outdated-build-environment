#!/bin/sh

# set -x

# Define the path for the event JSON file
JSON_FILE="/tmp/send.json"

# Ensure RelayLink is installed and ready to use
./install/install_relay_link.sh

# Read the event JSON from the send.json file
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: No event JSON provided"
    exit 1
fi

EVENT_JSON=$(cat "$JSON_FILE")

# Ensure the event JSON is valid
if [ -z "$EVENT_JSON" ]; then
    echo "Error: Event JSON is empty"
    exit 1
fi

# Check if relays are passed as arguments
if [ -z "$1" ]; then
    echo "Error: No relays provided"
    exit 1
fi

# Convert the comma-separated relays string into an array
RELAYS=$(echo "$1" | tr ',' ' ')

echo "JSON being sent: $EVENT_JSON"

# Publish Event to Relays
success_count=0
total_relays=0
for RELAY in $RELAYS; do
    total_relays=$((total_relays + 1))
    echo "Publishing to $RELAY..."
    RESPONSE=$(/tmp/./RelayLink "$RELAY" "$EVENT_JSON" "NULL")
    echo "Response: $RESPONSE"
    if echo "$RESPONSE" | grep -q '"OK"'; then
        echo "Success: Event accepted by $RELAY."
        success_count=$((success_count + 1))
    else
        echo "Error: Event not accepted by $RELAY. Response: $RESPONSE"
    fi
done

# Check if any publications succeeded
if [ "$success_count" -eq 0 ]; then
    echo "Error: All relay publications failed."
    exit 1
else
    echo "Success: Published to $success_count out of $total_relays relay(s)."
fi

