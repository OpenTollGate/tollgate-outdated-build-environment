#!/bin/sh

# Define file paths and constants
JSON_FILE="nostr_keys.json"
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CHECKSUMS_FILE="$SCRIPT_DIR/checksums.json"
OUTPUT_FILE="/tmp/send.json"

# URLs of the binaries and checksums
CHECKSUMS_URL="https://github.com/chGoodchild/nostrSigner/releases/download/v0.0.4/checksums.json"
SIGN_EVENT_URL_LOCAL="https://github.com/chGoodchild/nostrSigner/releases/download/v0.0.4/sign_event_local"
SIGN_EVENT_URL_MIPS="https://github.com/chGoodchild/nostrSigner/releases/download/v0.0.4/sign_event_mips"

# Paths to download binaries
TMP_DIR="/tmp"
SIGN_EVENT_BIN_LOCAL="$TMP_DIR/sign_event_local"
SIGN_EVENT_BIN_MIPS="$TMP_DIR/sign_event_mips"

# Check and download checksums.json if it doesn't exist
if [ ! -f "$CHECKSUMS_FILE" ]; then
    echo "Downloading checksums.json..."
    wget -q $CHECKSUMS_URL -O $CHECKSUMS_FILE
fi

# Function to download and ensure the binary is executable
download_and_ensure_executable() {
    url=$1
    path=$2
    expected_hash=$3
    if [ ! -f "$path" ]; then
        echo "Downloading $path..."
        wget -q $url -O $path
    fi

    verify_checksum $path $expected_hash

    if [ ! -x "$path" ]; then
        echo "Setting execute permission on $path"
        chmod +x $path
    fi
}

# Function to verify the checksum of a file
verify_checksum() {
    path=$1
    expected_hash=$2
    actual_hash=$(sha256sum $path | awk '{print $1}')
    if [ "$actual_hash" != "$expected_hash" ]; then
        echo "Checksum verification failed for $path"
        echo "Expected: $expected_hash"
        echo "Actual: $actual_hash"
        exit 1
    fi
    echo "Checksum verification passed for $path"
}

# Determine the architecture of the current system
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        BIN_PATH=$SIGN_EVENT_BIN_LOCAL
        EXPECTED_HASH=$(jq -r '.sign_event_local_checksum' $CHECKSUMS_FILE)
        DOWNLOAD_URL=$SIGN_EVENT_URL_LOCAL
        ;;
    mips)
        BIN_PATH=$SIGN_EVENT_BIN_MIPS
        EXPECTED_HASH=$(jq -r '.sign_event_mips_checksum' $CHECKSUMS_FILE)
        DOWNLOAD_URL=$SIGN_EVENT_URL_MIPS
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Download the binary if it does not exist or is not executable and verify its checksum
download_and_ensure_executable $DOWNLOAD_URL $BIN_PATH $EXPECTED_HASH

# Function to generate event and JSON
generate_event_json() {
    # Extract keys and identifiers
    PUBLIC_KEY_HEX=$(jq -r '.npub_hex' "$JSON_FILE")
    PRIVATE_KEY_HEX=$(jq -r '.nsec_hex' "$JSON_FILE")

    # Event data
    CONTENT=${1:-"Hello, Nostr!"}
    CREATED_AT=$(date +%s)
    SERIALIZED_EVENT="[0,\"$PUBLIC_KEY_HEX\",$CREATED_AT,1,[],\"$CONTENT\"]"
    
    # Generate the SHA-256 hash of the serialized event
    EVENT_HASH=$(echo -n "$SERIALIZED_EVENT" | sha256sum | awk '{print $1}')

    # Sign the hash using the private key
    SIGNATURE=$($BIN_PATH "$EVENT_HASH" "$PRIVATE_KEY_HEX")
    
    # Generate the event ID by hashing the serialized event
    EVENT_ID=$(echo -n "$SERIALIZED_EVENT" | sha256sum | awk '{print $1}')

    # Create the event JSON
    EVENT=$(jq -n --arg id "$EVENT_ID" --arg pubkey "$PUBLIC_KEY_HEX" --argjson created_at "$CREATED_AT" --arg content "$CONTENT" --arg sig "$SIGNATURE" '{
        "id": $id,
        "pubkey": $pubkey,
        "created_at": $created_at,
        "kind": 1,
        "tags": [],
        "content": $content,
        "sig": $sig
    }')

    echo '["EVENT",' "$EVENT" ']' > $OUTPUT_FILE
    cat $OUTPUT_FILE
}

# Main execution flow
generate_event_json "$@"

