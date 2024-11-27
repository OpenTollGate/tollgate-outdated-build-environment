#!/bin/sh

# Define URLs and file paths
KEYGEN_SCRIPT_URL="https://github.com/chGoodchild/TollGateNostrToolKit/releases/download/v0.0.6/generate_npub_optimized"
KEYGEN_PROGRAM="/tmp/generate_npub"
EXPECTED_HASH="32197ad721a607f140c862dc40c7d4ccec77afd47b0978d6449767d099d2ff55"
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
OUTPUT_FILE="/nostr/shell/nostr_keys.json"

# Function to download and verify the keygen script
download_and_verify_script() {
    echo "Downloading generate_npub..."
    # Download the keygen script using curl with -L to follow redirects
    curl -L -o $KEYGEN_PROGRAM $KEYGEN_SCRIPT_URL

    # Calculate the current file's hash
    CURRENT_HASH=$(sha256sum $KEYGEN_PROGRAM | awk '{ print $1 }')

    # Verify the checksum
    if [ "$CURRENT_HASH" != "$EXPECTED_HASH" ]; then
        echo "Error: Checksum verification failed."
        exit 1
    fi

    # Make the keygen script executable
    chmod +x $KEYGEN_PROGRAM
}

# Check if the keygen script is already present and matches the expected SHA-256 hash
if [ -f "$KEYGEN_PROGRAM" ]; then
    CURRENT_HASH=$(sha256sum $KEYGEN_PROGRAM | awk '{ print $1 }')
    if [ "$CURRENT_HASH" != "$EXPECTED_HASH" ]; then
        echo "generate_npub is outdated or corrupted. Downloading a fresh copy."
        download_and_verify_script
    else
        echo "generate_npub is up to date."
    fi
else
    # If the script is not present, download it
    download_and_verify_script
fi

