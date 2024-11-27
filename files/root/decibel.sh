#!/bin/sh

# Show usage if no argument provided
usage() {
    echo "Usage: $0 <number>"
    echo "Calculates 10 * log10(number)"
    exit 1
}

# Check if we have an argument
if [ $# -ne 1 ]; then
    usage
fi

# Validate input is a number
if ! echo "$1" | grep -Eq '^[0-9]+\.?[0-9]*$'; then
    echo "Error: Input must be a positive number"
    usage
fi

# Calculate 10 * log10(input)
awk "BEGIN { printf \"%.1f\", 10 * log($1)/log(10) }"
