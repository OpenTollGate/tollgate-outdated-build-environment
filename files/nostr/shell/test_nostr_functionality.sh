#!/bin/sh

# Enable debugging to show commands and their arguments as they are executed
# set -x

# RELAYS="wss://puravida.nostr.land,wss://eden.nostr.land,wss://relay.snort.social,wss://orangesync.tech"

# RELAYS="wss://puravida.nostr.land,wss://eden.nostr.land,wss://relay.snort.social,wss://nostr.wine,wss://orangesync.tech,wss://atlas.nostr.land,wss://nostr-pub.wellorder.net,wss://nostr.mom,wss://relay.nostr.com.au,wss://filter.nostr.wine,wss://nostr.milou.lol,wss://relay.orangepill.dev,wss://relay.nostr.band,wss://relay.noswhere.com,wss://nostr.inosta.cc,wss://nos.lol,wss://nostr.bitcoiner.social,wss://relay.damus.io,wss://relay.nostr.bg,wss://nostr.oxtr.dev"

./install/install_jq.sh

# Function to check if a file exists and is not empty
check_file() {
    if [ -s "$1" ]; then
        echo "SUCCESS: $1 exists and is not empty."
    else
        echo "\n\n ./generate_keys.sh"
        echo "\n\n check_file $1"
        echo "\n\n ./note_generator.sh \"$NOTE_CONTENT\""
        echo "ERROR: $1 does not exist or is empty."
        exit 1
    fi
}

# Function to run the generate_keys.sh script
generate_keys() {
    ./generate_keys.sh
    check_file "nostr_keys.json"
}

# Function to run the note_generator.sh script
generate_note() {
    ./note_generator.sh "$NOTE_CONTENT"
    check_file "/tmp/send.json"
}

# Function to run the publish.sh script
publish_events() {
    PUBLISH_OUTPUT=$(./publish.sh "$RELAYS")
    if echo "$PUBLISH_OUTPUT" | grep -q "Success: Published to"; then
        echo "SUCCESS: publish.sh ran successfully and the event was accepted by the relay."
    else
        echo "\n\n ./publish.sh \"$RELAYS\""
        echo "ERROR: publish.sh failed or the event was not accepted by the relay."
        exit 1
    fi
}

# Function to run the fetch_notes.sh script
fetch_notes() {
    FETCH_OUTPUT=$(./fetch_notes.sh "$RELAYS" "$NPUB")
    # Check for the expected NOTE_CONTENT within the fetched notes
    if echo "$FETCH_OUTPUT" | grep -q "$NOTE_CONTENT"; then
        echo "SUCCESS: fetch_notes.sh ran successfully and the event was fetched."
    else
        echo "\n\n ./fetch_notes.sh \"$RELAYS\" \"$NPUB\""
        echo "ERROR: fetch_notes.sh did not fetch the expected event. Expected content not found."
        exit 1
    fi
}

# Main execution flow
generate_keys

NOTE_CONTENT="Hello, Nostr from $(uname -m)@$(date +%s)"
NPUB=$(jq -r '.npub_hex' nostr_keys.json)
# RELAYS="wss://orangesync.tech"
RELAYS="wss://tollbooth.stens.dev"


generate_note
publish_events
fetch_notes

echo "\nAll tests passed successfully."

# Disable debugging to clean up output
# set +x

