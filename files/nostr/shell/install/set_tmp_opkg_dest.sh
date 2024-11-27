#!/bin/sh

# Define the line to add
LINE="dest tmp /tmp"

# Check if the line is already present in the file
if ! grep -Fxq "$LINE" /etc/opkg.conf; then
    echo "Adding 'dest tmp /tmp' to /etc/opkg.conf"
    echo "$LINE" >> /etc/opkg.conf
else
    echo "'dest tmp /tmp' is already present in /etc/opkg.conf"
fi
