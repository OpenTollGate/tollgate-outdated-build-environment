#!/bin/sh

# Check if correct number of arguments provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <network> <port>"
    echo "Example: $0 192.168.1 2121"
    exit 1
fi

# Assign arguments to variables
NETWORK="$1"
PORT="$2"
TMPFILE="/tmp/port_scan.tmp"

# Validate port number
if ! echo "$PORT" | grep -q "^[0-9]\+$" || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
    echo "Error: Invalid port number. Port must be between 1 and 65535."
    exit 1
fi

# Validate network address format
if ! echo "$NETWORK" | grep -q "^[0-9]\+\.[0-9]\+\.[0-9]\+$"; then
    echo "Error: Invalid network format. Use format like '192.168.1'"
    exit 1
fi

rm -f $TMPFILE

echo "Scanning network $NETWORK.0/24 for devices with port $PORT open..."

# Run scans in parallel with a maximum of 5 concurrent processes
for i in $(seq 1 254); do
    (
        if echo -e "GET / HTTP/1.1\r\nHost: $NETWORK.$i:$PORT\r\n\r\n" | nc $NETWORK.$i $PORT 2>/dev/null | grep -q "HTTP/1.1 200 OK"; then
            echo "$NETWORK.$i" >> $TMPFILE
        fi
    ) &
    # Limit concurrent processes
    if [ $(jobs -p | wc -l) -ge 5 ]; then
        wait -n
    fi
done

# Wait for remaining scans to complete
wait

if [ -f $TMPFILE ]; then
    echo "\nDevices responding on port $PORT:"
    sort -n -t . -k 4 $TMPFILE
    rm $TMPFILE
else
    echo "\nNo devices found responding on port $PORT"
fi
