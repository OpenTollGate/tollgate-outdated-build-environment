#!/bin/sh

# Function to extract JSON events and sort by timestamp
get_latest_event() {
    local relay=$1
    local pubkey=$2
    
    # Run fetch_notes.sh and capture output, redirect stderr to /dev/null
    output=$(./fetch_notes.sh "$relay" "$pubkey" 2>/dev/null)
    
    # Extract EVENT lines, get the most recent one, and extract just the JSON object part
    echo "$output" | grep '^\["EVENT"' | sort -r | head -n 1 | sed 's/\["EVENT","sub1",$.*$]/\1/'
}

# Check if arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <relay_url> <pubkey>"
    exit 1
fi

# Call function with provided arguments
get_latest_event "$1" "$2"
