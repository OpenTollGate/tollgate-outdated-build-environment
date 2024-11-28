#!/bin/sh

# Run scan_ports.sh and save output to variable
SCAN_OUTPUT=$(./scan_ports.sh 119.201.26 7777)

# Extract first IP address after the "Devices responding" line
FIRST_IP=$(echo "$SCAN_OUTPUT" | grep -A1 "Devices responding on port" | tail -n1)

# Print the first IP
echo "$FIRST_IP"
