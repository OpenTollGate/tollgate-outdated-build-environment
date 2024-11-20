#!/bin/sh

# Usage: ./redeem.sh <token_file_path> [-u username | -l lightning_address]
# Examples: 
# ./redeem.sh token.txt -u user-86f52
# ./redeem.sh token.txt -l user@lightning.address

BOARDWALK_ENDPOINT="https://boardwalk-git-feat-post-token-makeprisms.vercel.app"

# Show usage if no arguments
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <token_file_path> [-u username | -l lightning_address]"
    exit 1
fi

token_file=$1
shift

# Parse arguments
while getopts "u:l:" opt; do
    case $opt in
        u) username="$OPTARG" ;;
        l) lightning_address="$OPTARG" ;;
        ?) echo "Usage: $0 <token_file_path> [-u username | -l lightning_address]" 
           exit 1 ;;
    esac
done

# Validate arguments
if [ -n "$username" ] && [ -n "$lightning_address" ]; then
    echo "{\"error\": \"Please specify either username OR lightning address, not both\"}"
    exit 1
fi

if [ -z "$username" ] && [ -z "$lightning_address" ]; then
    echo "{\"error\": \"Please specify either username or lightning address\"}"
    exit 1
fi

# Check if file exists
if [ ! -f "$token_file" ]; then
    echo "{\"error\": \"Token file not found\"}"
    exit 1
fi

# Read token from file
token=$(cat "$token_file")

# Prepare JSON payload and endpoint
if [ -n "$username" ]; then
    json_payload="{\"token\": \"$token\"}"
    endpoint="$BOARDWALK_ENDPOINT/api/users/username/$username/token"
else
    json_payload="{\"token\": \"$token\", \"lightning_address\": \"$lightning_address\"}"
    endpoint="$BOARDWALK_ENDPOINT/api/melt"
fi

# Make the API call and store response
response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$json_payload" \
    "$endpoint")

# Output response as JSON
echo "$response"
