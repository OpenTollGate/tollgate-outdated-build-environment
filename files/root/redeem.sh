#!/bin/sh

# Take a file containing ecash token and send it to a boardwalk user
# Usage: ./redeem.sh <token_file_path> <boardwalk_username>

BOARDWALK_ENDPOINT="https://boardwalk-git-feat-post-token-makeprisms.vercel.app"

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <token_file_path> <boardwalk_username>"
    exit 1
fi

token_file=$1
boardwalk_username=$2

# Check if file exists
if [ ! -f "$token_file" ]; then
    echo "{\"error\": \"Token file not found\"}"
    exit 1
fi

# Read token from file
token=$(cat "$token_file")

# Make the API call and store response
response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"token\": \"$token\"}" \
    "$BOARDWALK_ENDPOINT/api/users/username/$boardwalk_username/token")

# Output response as JSON
echo "$response"
