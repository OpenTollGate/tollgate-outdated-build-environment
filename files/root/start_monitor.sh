#!/bin/sh

# Check if mon0 interface exists
if ! iw dev | grep -q "Interface mon0"; then
    # Bring down sta interface if it exists
    if iw dev | grep -q "Interface phy0-sta0"; then
        ip link set phy0-sta0 down
    fi
    
    # Create monitor interface
    iw phy phy0 interface add mon0 type monitor
    
    # Bring up mon0
    ip link set mon0 up
    
    echo "Monitor interface mon0 created and started"
else
    # Check if mon0 is down
    if ip link show mon0 | grep -q "state DOWN"; then
        ip link set mon0 up
        echo "Monitor interface mon0 started"
    else
        echo "Monitor interface mon0 is already running"
    fi
fi
