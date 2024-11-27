#!/bin/sh

# Ensure RelayLink is installed and ready to use
./install/install_relay_link.sh

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Error: Incorrect number of arguments."
    echo "Usage: $0 '<relays>' '<public_key>'"
    exit 1
fi

# Extract and validate the relay URLs and public key from arguments
RELAYS=$1
PUBLIC_KEY=$2

if [ -z "$RELAYS" ]; then
    echo "Error: No relay URLs provided."
    exit 1
fi

if [ -z "$PUBLIC_KEY" ]; then
    echo "Error: Public key not provided."
    exit 1
fi

# Define the subscription ID and the timestamp to fetch events from
SUBSCRIPTION_ID="sub1"
CURRENT_TIMESTAMP=$(date +%s)
SINCE_TIMESTAMP=$((CURRENT_TIMESTAMP - 600))  # Fetch events from the last 10 minutes

# Create a subscription request
SUBSCRIPTION_REQUEST=$(jq -c -n --arg id "$SUBSCRIPTION_ID" --arg key "$PUBLIC_KEY" --argjson since "$SINCE_TIMESTAMP" '[ "REQ", $id, { "authors": [ $key ], "since": $since } ]')

# Print the subscription request and timestamps for debugging
echo "Subscription Request: $SUBSCRIPTION_REQUEST"
echo "Current Timestamp: $CURRENT_TIMESTAMP"
echo "Since Timestamp: $SINCE_TIMESTAMP"

# Function to parse and print the notes from the relay messages
parse_and_print_notes() {
    while IFS= read -r message; do
        echo "$message"
        if echo "$message" | jq -e '.[0] == "EVENT"' > /dev/null; then
            event=$(echo "$message" | jq -c '.[2]')
            content=$(echo "$event" | jq -r '.content')
            # echo "Note Content: $content"
        elif echo "$message" | jq -e '.[0] == "EOSE"' > /dev/null; then
            echo "EOSE received. No more events."
            break
        else
            echo "Notice or Error from Relay: $message"
        fi
    done
}

# Function to subscribe to a relay and listen for messages
subscribe_to_relay() {
    RELAY=$1
    echo "Connecting to $RELAY"
    # Send subscription request and parse messages
    /tmp/./RelayLink "$RELAY" "$SUBSCRIPTION_REQUEST" "$PUBLIC_KEY"
}

# Subscribe to each relay
OLD_IFS="$IFS"
IFS=','
for RELAY in $RELAYS; do
    subscribe_to_relay "$RELAY"
done
IFS="$OLD_IFS"

# Wait for all background jobs to finish
wait

