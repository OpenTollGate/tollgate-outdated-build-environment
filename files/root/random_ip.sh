#!/bin/sh

FIRST_BOOT_FLAG="/etc/first_boot_completed"
OPENNDS_CONFIG="/etc/config/opennds"
HOSTS_FILE="/etc/hosts"

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
    
    # Update OpenNDS config
    uci set opennds.@opennds[0].statuspath="$RANDOM_IP"
    uci commit opennds
    
    # Update hosts file
    # First, remove old status.client entry if it exists
    sed -i '/status.client/d' $HOSTS_FILE
    
    # Add new status.client entry
    echo "$RANDOM_IP status.client" >> $HOSTS_FILE
    
    # Create flag file to indicate first boot completed
    touch "$FIRST_BOOT_FLAG"
    
    # Restart network and OpenNDS
    /etc/init.d/network restart
    /etc/init.d/opennds restart
fi
