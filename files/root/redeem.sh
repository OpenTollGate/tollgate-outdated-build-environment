#!/bin/sh

# Take any token as input and sendi it to a boardwalk user
# Usage: send_token_to_boardwalk.sh <token> <boardwalk_username>

BOARDWALK_ENDPOINT="https://boardwalk-git-feat-post-token-makeprisms.vercel.app"

token=$1
boardwalk_username=$2

response=$(curl -s -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{\"token\": \"$token\"}" "$BOARDWALK_ENDPOINT/api/users/username/$boardwalk_username/token")

echo "$response"

http_code=$(echo "$response" | tail -c 4)
body=$(echo "$response" | head -c -4)

if [ "$http_code" != "200" ]; then
    error_msg=$(echo "$body" | jq -r '.error // "Unknown error"')
    echo "Error: HTTP status code $http_code - $error_msg"
    exit 1
fi

amount_sats=$(echo "$body" | jq -r '.amountSats')
echo ""
echo "=========================================================="
echo "Successfully sent $amount_sats sats to $boardwalk_username"
echo "============================================================"
