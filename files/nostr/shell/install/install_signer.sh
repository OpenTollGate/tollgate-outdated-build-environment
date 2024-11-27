#!/bin/sh

# Get the directory of this script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Define architecture specific details
ARCH=$(uname -m)
CHECKSUMS_FILE="/tmp/checksums.json"
CHECKSUMS_URL="https://github.com/chGoodchild/nostrSigner/releases/download/v0.0.1/checksums.json"
INSTALL_DIR="$SCRIPT_DIR/.."

# Download the checksums file if it doesn't exist
if [ ! -f "$CHECKSUMS_FILE" ]; then
    echo "Downloading checksums.json..."
    wget -q $CHECKSUMS_URL -O $CHECKSUMS_FILE
fi

case $ARCH in
    x86_64)
        BINARY_URL="https://github.com/chGoodchild/nostrSigner/releases/download/v0.0.1/sign_event_local"
        BINARY_PATH="/tmp/sign_event_local"
        TARGET_BINARY_PATH="$INSTALL_DIR/sign_event_local"
        EXPECTED_HASH=$(jq -r '.local_binary_checksum' $CHECKSUMS_FILE)
        ;;
    mips)
        BINARY_URL="https://github.com/chGoodchild/nostrSigner/releases/download/v0.0.1/sign_event_mips"
        BINARY_PATH="/tmp/sign_event_mips"
        TARGET_BINARY_PATH="$INSTALL_DIR/sign_event_mips"
        EXPECTED_HASH=$(jq -r '.mips_binary_checksum' $CHECKSUMS_FILE)
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Function to download and verify the binary
download_and_verify_binary() {
    echo "Downloading $TARGET_BINARY_PATH..."
    wget -q $BINARY_URL -O $BINARY_PATH
    CURRENT_HASH=$(sha256sum $BINARY_PATH | awk '{ print $1 }')
    
    if [ "$CURRENT_HASH" != "$EXPECTED_HASH" ]; then
        echo "Error: Checksum verification failed."
        exit 1
    fi

    chmod +x $BINARY_PATH
    mv $BINARY_PATH $TARGET_BINARY_PATH
}

# Check if the binary is already in the install directory and has the correct checksum
if [ -f "$TARGET_BINARY_PATH" ]; then
    CURRENT_HASH=$(sha256sum $TARGET_BINARY_PATH | awk '{ print $1 }')
    if [ "$CURRENT_HASH" = "$EXPECTED_HASH" ]; then
        # echo "$TARGET_BINARY_PATH is up to date."
        exit 0
    else
        download_and_verify_binary
    fi
else
    download_and_verify_binary
fi

echo "Setup complete for note signer."

