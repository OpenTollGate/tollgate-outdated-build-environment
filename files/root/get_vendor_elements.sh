#!/bin/sh

# Check for required arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <SSID> <bytes>"
    echo "Example: $0 TollGate_c2d0cfda 12"
    exit 1
fi

SSID="$1"
BYTES="$2"

# Create temporary file
tmpfile=$(mktemp)

/root/./start_monitor.sh > /dev/null 2>&1

# Start tcpdump in background and give it time to capture packets
tcpdump -l -i mon0 -e -s 0 -xx type mgt subtype beacon 2>/dev/null > "$tmpfile" &
tcpdump_pid=$!

# Wait for some data to be captured (3 seconds)
sleep 3

# Kill tcpdump
kill \$tcpdump_pid 2>/dev/null

# Process the file
grep_output=$(grep -A 15 "$SSID" "$tmpfile")
parse_output=$(echo "$grep_output" | ./parse_beacon.sh "$SSID" "$BYTES")
final_output=$(echo "$parse_output" | head -n 1)

# Debug output (optional)
# echo "Debug: Captured data size: \$(wc -l < "$tmpfile") lines" >&2
# echo "Debug: Grep output size: \$(echo "$grep_output" | wc -l) lines" >&2

# Clean up
rm "$tmpfile"

# Extract hex values from vendor elements
# Example vendor elements: dd0c212121010009467400000033
# Skip first 4 chars (dd0c) to get to the payload
payload=${final_output:4}
kb_allocation_hex=${payload:8:8}
contribution_hex=${payload:16:8}

# Convert hex to decimal using printf
kb_allocation_decimal=$(printf "%d" "0x${kb_allocation_hex}" 2>/dev/null)
contribution_decimal=$(printf "%d" "0x${contribution_hex}" 2>/dev/null)

# Create JSON file
cat > /tmp/vendor_elements.json << EOF
{
    "kb_allocation_hex": "${kb_allocation_hex}",
    "kb_allocation_decimal": ${kb_allocation_decimal},
    "contribution_hex": "${contribution_hex}",
    "contribution_decimal": ${contribution_decimal},
    "vendor_elements": "${final_output}"
}
EOF

# Output the final result
# echo "$final_output"
cat /tmp/vendor_elements.json
