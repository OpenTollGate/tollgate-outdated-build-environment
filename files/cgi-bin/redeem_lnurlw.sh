#!/bin/sh -e

# Enable error tracking and debugging
# set -x  # Uncomment for debugging

# API URLs
LNURL_DECODE_API_URL="https://demo.lnbits.com/api/v1/payments/decode"
LNURLP_URL="https://minibits.cash/.well-known/lnurlp/chandran"
API_KEY="5d0605a2fa0d4d6c8fe13fdec25720ca"

# Accept LNURLW, amount, and verbose as arguments
LNURLW="$1"
AMOUNT="$2"  # New amount parameter in millisatoshis
VERBOSE="${3:-false}"

# Check if LNURLW and amount are provided
if [ -z "$LNURLW" ] || [ -z "$AMOUNT" ]; then
    echo "Error: Both LNURLW and amount parameters are required"
    echo "Usage: $0 <LNURLW> <amount_in_millisats> [verbose]"
    echo "Example: $0 LNURL... 8000 true"
    exit 1
fi

# Validate amount is a number
if ! echo "$AMOUNT" | grep -q '^[0-9]\+$'; then
    echo "Error: Amount must be a positive number in millisatoshis"
    exit 1
fi

# Function to print verbose messages
log_verbose() {
    if [ "$VERBOSE" = "true" ]; then
        echo "$1"
    fi
}

# Step 1: Decode the LNURLw using the API
decode_response=$(curl -s -X POST $LNURL_DECODE_API_URL -d "{\"data\": \"$LNURLW\"}" -H "X-Api-Key: $API_KEY" -H "Content-type: application/json")
decoded_url=$(echo $decode_response | jq -r '.domain')

log_verbose "Decoded URL: $decoded_url"

# Check if the decoded URL is valid
if [ -z "$decoded_url" ]; then
    echo "Error: Decoded URL is empty. Decoding failed."
    exit 1
fi

# Step 2: Visit the decoded URL to fetch withdrawal information
withdraw_info=$(curl -s "$decoded_url")
log_verbose "Withdrawal Info: $withdraw_info"

# Extract callback URL and k1 value
callback_url=$(echo $withdraw_info | jq -r '.callback')
k1=$(echo $withdraw_info | jq -r '.k1')
max_withdrawable=$(echo $withdraw_info | jq -r '.maxWithdrawable')

# Check if callback URL and k1 value were extracted successfully
if [ -z "$callback_url" ] || [ -z "$k1" ]; then
    echo "Error: Failed to extract callback URL or k1 value."
    exit 1
fi

log_verbose "Callback URL: $callback_url"
log_verbose "k1: $k1"

# Step 3: Get the dynamic BOLT11 invoice using the LNURLp
get_bolt11_invoice() {
    log_verbose "Getting BOLT11 invoice..."
    lnurlp_response=$(curl -s "$LNURLP_URL")
    max_sendable=$(echo $lnurlp_response | jq -r '.maxSendable')
    
    log_verbose "Max sendable amount: $max_sendable msats"
    
    # Use the amount provided as argument
    lnurl_payment_request=$(curl -s "$LNURLP_URL?amount=$AMOUNT")
    bolt11_invoice=$(echo $lnurl_payment_request | jq -r '.pr')
    
    if [ -z "$bolt11_invoice" ]; then
        echo "Error: Failed to retrieve BOLT11 invoice."
        exit 1
    fi
    
    log_verbose "BOLT11 Invoice: $bolt11_invoice"
    echo $bolt11_invoice
}

# Retrieve the BOLT11 invoice dynamically
BOLT11_INVOICE=$(get_bolt11_invoice | tail -n 1)

# Step 4: Submit the BOLT11 invoice
full_callback_url="${callback_url}?k1=${k1}&pr=${BOLT11_INVOICE}"
log_verbose "Full Callback URL: $full_callback_url"

response=$(curl -s "$full_callback_url")

# Check if the response was successful
if echo "$response" | grep -q '"status":"OK"'; then
    echo "{\"status\":\"OK\", \"paid_amount\":$max_withdrawable}"
else
    echo "Error: Failed to get a successful response from the callback URL."
    log_verbose "Response: $response"
    exit 1
fi

