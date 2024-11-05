#!/bin/sh

FIRST_BOOT_FLAG="/etc/first_boot_completed"

if [ ! -f "$FIRST_BOOT_FLAG" ]; then
    # Generate random numbers between 1-254 for each octet
    OCTET1=$((RANDOM % 254 + 1))
    OCTET2=$((RANDOM % 254 + 1))
    OCTET3=$((RANDOM % 254 + 1))
    
    # Construct the random IP with last octet as 1
    RANDOM_IP="$OCTET1.$OCTET2.$OCTET3.1"
    
    # Update network config
    uci set network.lan.ipaddr=$RANDOM_IP
    uci commit network
    
    # Create flag file to indicate first boot completed
    touch "$FIRST_BOOT_FLAG"
    
    # Restart network
    /etc/init.d/network restart
fi
