#!/bin/sh

# Check if correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <MAC_ADDRESS> <LNURLW_CODE>"
    exit 1
fi

MAC_ADDRESS=$1
LNURLW_CODE=$2
JSON_FILE="/tmp/lnurlws.json"

# Create file with empty JSON object if it doesn't exist
if [ ! -f "$JSON_FILE" ]; then
    echo '{}' > "$JSON_FILE"
fi

# Validate JSON file
if ! jq empty "$JSON_FILE" 2>/dev/null; then
    echo "Error: Invalid JSON in $JSON_FILE"
    exit 1
fi

# Update or add the MAC address and LNURLW pair
jq --arg mac "$MAC_ADDRESS" --arg lnurlw "$LNURLW_CODE" \
    '. + {($mac): $lnurlw}' "$JSON_FILE" > "$JSON_FILE.tmp" && \
    mv "$JSON_FILE.tmp" "$JSON_FILE"

# Set appropriate permissions
chmod 644 "$JSON_FILE"

exit 0
