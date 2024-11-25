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

# Extract components using sed
length_hex=$(echo "$hex" | sed 's/^dd$..$.*/\1/')
oui=$(echo "$hex" | sed 's/^dd..$...$.*/\1/')
type=$(echo "$hex" | sed 's/^dd..$....$..$.*$/\2/' | cut -c1-2)
kb_allocation_hex=$(echo "$hex" | sed 's/^dd..$....$..$.*$/\2/' | cut -c3-10)
contribution_hex=$(echo "$hex" | sed 's/^dd..$....$..$.*$/\2/' | cut -c11-18)

# Convert hex to decimal
length=$(printf "%d" "0x$length_hex")
kb_allocation=$(printf "%d" "0x$kb_allocation_hex")
contribution_sats=$(printf "%d" "0x$contribution_hex")

# Calculate derived values
mb_allocation=$(awk "BEGIN {printf \"%.3f\", $kb_allocation/1024}")
gb_allocation=$(awk "BEGIN {printf \"%.3f\", $kb_allocation/1024/1024}")

# Output JSON
cat << EOF
{
    "vendor_elements": {
        "raw_hex": "$hex",
        "length": $length,
        "oui": "$oui",
        "type": "$type",
        "kb_allocation": $kb_allocation,
        "mb_allocation": $mb_allocation,
        "gb_allocation": $gb_allocation,
        "contribution_sats": $contribution_sats
    }
}
EOF
