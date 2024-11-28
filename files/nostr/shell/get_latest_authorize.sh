#!/bin/sh

# Function to extract JSON events and sort by timestamp
get_latest_event() {
    local relay=$1
    local pubkey=$2
    
    # Run fetch_notes.sh and capture output, redirect stderr to /dev/null
    output=$(./fetch_notes.sh "$relay" "$pubkey" 2>/dev/null)
    
    # Extract EVENT lines, get the most recent one
    latest=$(echo "$output" | grep '^\["EVENT"' | sort -r | head -n 1)

    # TODO: Remove the first 16 characters from the beginning of the remaining string: ["EVENT","sub1",
    # TODO: Remove the last 1 character from the end of the remaining string: ]
    # ["EVENT","sub1",{"content":"cashuAbcde","created_at":1732732656,"id":"2b3a0b3e7b0473919d1506354da41433313d58e5677a9bed2c4eb55f07c2b38f","kind":66666,"pubkey":"a057f743eca9efe9c97e6358bf2b37b05349029edfaa1a5e6e0c117fc95b9114","sig":"34a4497da2c963b23f8403f77be56299e66e51bc8af29ecf3bb55d1c419cdd8a462d5d276525debb132dad08f66d49f79a0b7439ee8f6ad526eb301f44a6be99","tags":[["p","02d9613afcd8c0e292dab9dfccf5fd508e323eecedd84530afd81d506da3703c"],["mac","lkjdsly3l3:ljld333:ljlk3jl3kj:kjdflkjdld"],["session-end","1732732716"]]}]

    echo "$latest" | cut -c 17- | sed 's/.$//'
}

# Check if arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <relay_url> <pubkey>"
    exit 1
fi

# Call function with provided arguments
get_latest_event "$1" "$2"
