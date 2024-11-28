#!/bin/sh

# Run scan_ports.sh and save output to variable
SCAN_OUTPUT=$(./scan_ports.sh 119.201.26 7777)

# Extract first IP address after the "Devices responding" line
FIRST_IP=$(echo "$SCAN_OUTPUT" | grep -A1 "Devices responding on port" | tail -n1)

# Print the first IP
echo "Relay IP: $FIRST_IP"

# Update lighttpd.conf with the new IP
# Using sed to replace the IP address in the proxy.server configuration
sed -i "s/\"host\" => \"[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\"/\"host\" => \"$FIRST_IP\"/" /etc/lighttpd/lighttpd.conf

# Restart lighttpd to apply changes
/etc/init.d/lighttpd restart
