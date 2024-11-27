#!/bin/sh

# Show usage if no arguments provided
usage() {
    echo "Usage: $0 <vendor_elements_hex>"
    echo "Example: $0 dd10212121010008dd2f00000033"
    exit 1
}

# Check if we have an argument
if [ $# -ne 1 ]; then
    usage
fi

# Get the hex string
hex="$1"

# Validate hex string format
if ! echo "$hex" | grep -Eq '^[0-9A-Fa-f]+$'; then
    echo "Error: Input must be hex digits"
    usage
fi

# Extract components
# Skip first 2 chars (dd), take next 2 for length
length_hex=$(echo "$hex" | dd bs=1 skip=2 count=2 2>/dev/null)
# Skip first 4 chars, take next 6 for OUI
oui=$(echo "$hex" | dd bs=1 skip=4 count=6 2>/dev/null)
# Skip first 10 chars, take next 2 for type
type=$(echo "$hex" | dd bs=1 skip=10 count=2 2>/dev/null)
# Skip first 12 chars, take next 8 for kb_allocation
kb_allocation_hex=$(echo "$hex" | dd bs=1 skip=12 count=8 2>/dev/null)
# Skip first 20 chars, take next 8 for contribution
contribution_hex=$(echo "$hex" | dd bs=1 skip=20 count=8 2>/dev/null)

# Convert hex to decimal
length=$(printf "%d" "0x$length_hex")
kb_allocation=$(printf "%d" "0x$kb_allocation_hex")
contribution_sats=$(printf "%d" "0x$contribution_hex")

# Calculate derived values
mb_allocation=$(awk "BEGIN {printf \"%.3f\", $kb_allocation/1024}")
gb_allocation=$(awk "BEGIN {printf \"%.3f\", $kb_allocation/1024/1024}")

# Calculate decibel values
kb_allocation_db=$(./decibel.sh $kb_allocation)
contribution_sats_db=$(./decibel.sh $contribution_sats)

# Output JSON
cat << EOF
{
    "vendor_elements": {
        "raw_hex": "$hex",
        "length": $length,
        "oui": "$oui",
        "type": "$type",
        "kb_allocation": $kb_allocation,
        "kb_allocation_db": $kb_allocation_db,
        "mb_allocation": $mb_allocation,
        "gb_allocation": $gb_allocation,
        "contribution_sats": $contribution_sats,
        "contribution_sats_db": $contribution_sats_db
    }
}
EOF
