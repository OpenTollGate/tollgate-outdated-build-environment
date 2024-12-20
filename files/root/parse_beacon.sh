#!/bin/sh

# Check for required arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <SSID> <bytes>"
    echo "Example: $0 TollGate_c2d0cfda 12"
    exit 1
fi

TARGET_SSID="$1"
BYTES="$2"

# Convert decimal bytes to hex for pattern matching
HEX_LENGTH=$(printf "%02x" "$BYTES")

process_hex_data() {
    local hex_data="$1"
    # Calculate hex characters directly from BYTES (not HEX_LENGTH)
    local hex_chars=$((BYTES * 2))
    local pattern="dd${HEX_LENGTH}[0-9a-f]{${hex_chars}}"
    echo "$hex_data" | grep -oiE "$pattern"
}

# Main processing loop
while IFS= read -r line; do
    if echo "$line" | grep -q "Beacon ($TARGET_SSID)"; then
        # Found matching SSID, read next lines for hex data
        hex_data=""
        count=0
        while [ $count -lt 15 ] && IFS= read -r hexline; do
            # Remove offset and extract hex bytes
            cleaned_hex=$(echo "$hexline" | sed -E 's/^[ \t]*[0-9a-fx]*:[ \t]*//; s/[ \t]//g')
            hex_data="${hex_data}${cleaned_hex}"
            count=$((count + 1))
        done

        # count=0
        if [ -n "$hex_data" ]; then
            result=$(process_hex_data "$hex_data")
            if [ -n "$result" ]; then
                echo "$result"
                exit 0  # Exit successfully after finding first match
            else
                # echo "Debug: No vendor element found in this frame" >&2
		# count=$((count + 1))
                exit 1 # Exit without match
            fi
        else
            echo "Debug: No hex data accumulated" >&2
        fi
    fi
done
