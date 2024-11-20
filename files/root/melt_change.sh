#!/bin/sh

# Show usage if no arguments
if [ "$#" -lt 2 ]; then
    echo "Error: Please provide destination type (-u or -l) and destination value"
    echo "Usage: $0 [-u username | -l lightning_address]"
    echo "Example: $0 -u username-123"
    echo "         $0 -l user@domain.com"
    exit 1
fi

CHANGE_FILE="/root/changeTokens.json"
TEMP_TOKEN_FILE="/tmp/temp_token.txt"
REDEEM_SCRIPT="/www/cgi-bin/redeem_boardwalk.sh"

# Parse arguments
while getopts "u:l:" opt; do
    case $opt in
        u) username="$OPTARG" ;;
        l) lightning_address="$OPTARG" ;;
        ?) echo "Usage: $0 [-u username | -l lightning_address]"
           exit 1 ;;
    esac
done

# Validate arguments
if [ -n "$username" ] && [ -n "$lightning_address" ]; then
    echo "Error: Please specify either username OR lightning address, not both"
    exit 1
fi

if [ -z "$username" ] && [ -z "$lightning_address" ]; then
    echo "Error: Please specify either username or lightning address"
    exit 1
fi

# Check if changeTokens.json exists
if [ ! -f "$CHANGE_FILE" ]; then
    echo "Error: $CHANGE_FILE not found"
    exit 1
fi

# Check if redeem script exists
if [ ! -f "$REDEEM_SCRIPT" ]; then
    echo "Error: $REDEEM_SCRIPT not found"
    exit 1
fi

# Read tokens array from the file
TOKENS=$(jq -r '.tokens[]' "$CHANGE_FILE")

if [ -z "$TOKENS" ]; then
    echo "No tokens found in $CHANGE_FILE"
    exit 0
fi

# Process each token
echo "$TOKENS" | while read -r token; do
    echo "Processing token: $token"
    
    # Write current token to temporary file
    echo "$token" > "$TEMP_TOKEN_FILE"
    
    # Try to redeem the token based on provided option
    if [ -n "$username" ]; then
        if $REDEEM_SCRIPT "$TEMP_TOKEN_FILE" -u "$username"; then
            echo "Successfully melted token for username: $username"
            
            # Remove the processed token from changeTokens.json
            NEW_TOKENS=$(jq --arg token "$token" '.tokens -= [$token]' "$CHANGE_FILE")
            echo "$NEW_TOKENS" > "$CHANGE_FILE"
        else
            echo "Failed to melt token for username: $username"
        fi
    else
        if $REDEEM_SCRIPT "$TEMP_TOKEN_FILE" -l "$lightning_address"; then
            echo "Successfully melted token for lightning address: $lightning_address"
            
            # Remove the processed token from changeTokens.json
            NEW_TOKENS=$(jq --arg token "$token" '.tokens -= [$token]' "$CHANGE_FILE")
            echo "$NEW_TOKENS" > "$CHANGE_FILE"
        else
            echo "Failed to melt token for lightning address: $lightning_address"
        fi
    fi
done

# Clean up temporary file
rm -f "$TEMP_TOKEN_FILE"

echo "Completed processing all tokens"
