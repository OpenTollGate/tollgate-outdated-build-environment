#!/bin/sh

##!/bin/sh -e
# set -x

# File path and LNURL can be passed as arguments to the script
TOKEN_FILE="$1"
RECIPIENT_LNURL="$2"
VERBOSE="false"

# Simple logging function that continues silently if it fails
log_message() {
    # Skip logging completely if file isn't writable
    [ -w "/tmp/arguments_log.md" ] && printf '%s\n' "$1" >> "/tmp/arguments_log.md" 2>/dev/null
}

# Function to check required dependencies (POSIX-compliant version)
check_dependencies() {
    # Check for jq
    if ! which jq >/dev/null 2>&1; then
        printf "Error: jq is not installed. Please install jq to process JSON data.\n"
        exit 1
    fi

    # Check for base64
    if ! which base64 >/dev/null 2>&1; then
        printf "Error: base64 is not installed. Please install coreutils for base64 support.\n"
        exit 1
    fi

    log_message "Dependencies check passed: jq and base64 are installed"
}

# Function to map domain to mint URL
map_domain_to_mint() {
    local domain="$1"
    case "$domain" in
        "minibits.cash" | "nimo.cash")
            echo "https://mint.$domain/Bitcoin"
            ;;
        "8333.space")
            echo "https://$domain"
            ;;
        "umint.cash")
            echo "https://stablenut.$domain"
            ;;
        *)
            # Default to mint subdomain if unknown
            echo "https://mint.$domain/Bitcoin"
            ;;
    esac
}

# Function to generate MINT_URL and LNURL from the recipient's LNURL
generate_urls() {
    if [ -z "$RECIPIENT_LNURL" ]; then
        echo "Error: Recipient's LNURL is not provided."
        echo "Usage: $0 <token_file_path> <username@domain>"
        exit 1
    fi

    # Extract username and domain from the LNURL
    USERNAME=$(echo "$RECIPIENT_LNURL" | cut -d '@' -f 1)
    DOMAIN=$(echo "$RECIPIENT_LNURL" | cut -d '@' -f 2)

    if [ -z "$USERNAME" ] || [ -z "$DOMAIN" ]; then
        echo "Error: Invalid LNURL format. Expected format: username@domain"
        exit 1
    fi

    # Generate MINT_URL
    MINT_URL=$(map_domain_to_mint "$DOMAIN")

    # Generate LNURL
    LNURL="https://$DOMAIN/.well-known/lnurlp/$USERNAME"

    [ "$VERBOSE" = "true" ] && echo "Generated MINT_URL: $MINT_URL"
    [ "$VERBOSE" = "true" ] && echo "Generated LNURL: $LNURL"
}

# Function to read token from file
read_token_from_file() {
    if [ ! -f "$TOKEN_FILE" ]; then
        echo "Error: File $TOKEN_FILE does not exist."
        exit 1
    fi
    TOKEN=$(cat "$TOKEN_FILE")
    if [ -z "$TOKEN" ]; then
        echo "Error: Token file is empty."
        exit 1
    fi
}

# Function to decode the token and calculate total amount
decode_token() {

    [ "$VERBOSE" = "true" ] && echo $TOKEN
    
    # Remove the 'cashuA' prefix before decoding
    BASE64_TOKEN=$(echo "$TOKEN" | cut -b 7-)

    [ "$VERBOSE" = "true" ] && echo "Base64 Token: $BASE64_TOKEN"

    # Clean up the base64 token to remove any invalid characters
    CLEANED_BASE64_TOKEN=$(echo "$BASE64_TOKEN" | tr -d '\n\r')
    [ "$VERBOSE" = "true" ] && echo "Cleaned Base64 Token: $CLEANED_BASE64_TOKEN"

    # Ensure proper padding
    PADDING=$((${#CLEANED_BASE64_TOKEN} % 4))
    if [ $PADDING -ne 0 ]; then
        CLEANED_BASE64_TOKEN="${CLEANED_BASE64_TOKEN}$(printf '%0.s=' $(seq 1 $((4 - PADDING))))"
    fi
    [ "$VERBOSE" = "true" ] && echo "Padded Base64 Token: $CLEANED_BASE64_TOKEN"

    # Decode base64, handle any errors
    DECODED_TOKEN=$(echo "$CLEANED_BASE64_TOKEN" | base64 --decode -w 0)
    if [ -z "$DECODED_TOKEN" ]; then
        echo "Error decoding token or token is empty."
        exit 1
    fi

    # Print the decoded JSON
    [ "$VERBOSE" = "true" ] && echo "Decoded JSON: $DECODED_TOKEN"

    # Validate JSON format
    if ! echo "$DECODED_TOKEN" | jq . > /dev/null 2>&1; then
        echo "Decoded token is not valid JSON."
        exit 1
    fi

    # Parse the JSON to extract necessary values
    TOTAL_AMOUNT=0
    PROOFS=$(echo "$DECODED_TOKEN" | jq -c '.token[0].proofs[]')
    PROOFS_JSON="["
    FIRST_PROOF=true
    for PROOF in $PROOFS; do
        AMOUNT=$(echo "$PROOF" | jq -r '.amount')
        TOTAL_AMOUNT=$((TOTAL_AMOUNT + AMOUNT))
        if [ "$FIRST_PROOF" = true ]; then
            PROOFS_JSON="$PROOFS_JSON$PROOF"
            FIRST_PROOF=false
        else
            PROOFS_JSON="$PROOFS_JSON,$PROOF"
        fi
    done
    PROOFS_JSON="$PROOFS_JSON]"

    # Print total amount for debugging purposes
    [ "$VERBOSE" = "true" ] && echo "Proofs JSON: $PROOFS_JSON"
    [ "$VERBOSE" = "true" ] && echo "Total amount to transfer: $TOTAL_AMOUNT sats"

    # Extract other necessary details from the first proof
    FIRST_PROOF=$(echo "$PROOFS" | head -n 1)
    PROOF_SECRET=$(echo "$FIRST_PROOF" | jq -r '.secret')
    PROOF_ID=$(echo "$FIRST_PROOF" | jq -r '.id')
    PROOF_C=$(echo "$FIRST_PROOF" | jq -r '.C')

    # Check if parsing was successful
    if [ -z "$PROOF_SECRET" ] || [ -z "$PROOF_ID" ] || [ -z "$PROOF_C" ]; then
        echo "Error parsing decoded token JSON"
        exit 1
    fi

    # Ensure TOTAL_AMOUNT is set correctly
    # echo "Amount paid: $TOTAL_AMOUNT sats"
}

# Function to get mint keys
get_mint_keys() {
    [ "$VERBOSE" = "true" ] && echo "Getting mint keys..."
    RESPONSE=$(curl -s "$MINT_URL/keys" \
        -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0' \
        -H 'Accept: application/json, text/plain, */*' \
        -H 'Accept-Language: en-US,en;q=0.5' \
        -H 'Accept-Encoding: gzip, deflate, br, zstd' \
        -H 'Referer: https://redeem.cashu.me/' \
        -H 'Origin: https://redeem.cashu.me' \
        -H 'Connection: keep-alive' \
        -H 'Sec-Fetch-Dest: empty' \
        -H 'Sec-Fetch-Mode: cors' \
        -H 'Sec-Fetch-Site: cross-site' \
        -H 'Sec-GPC: 1' \
        -H 'Priority: u=1' \
        -H 'TE: trailers')
    [ "$VERBOSE" = "true" ] && echo "Mint keys response: $RESPONSE"
}

# Function to check the token and validate the proof values
check_token() {
    [ "$VERBOSE" = "true" ] && echo "Checking token..."
    RESPONSE=$(curl -s -X POST "$MINT_URL/check" \
        -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0' \
        -H 'Accept: application/json, text/plain, */*' \
        -H 'Accept-Language: en-US,en;q=0.5' \
        -H 'Accept-Encoding: gzip, deflate, br, zstd' \
        -H 'Referer: https://redeem.cashu.me/' \
        -H 'Content-Type: application/json' \
        -H 'Origin: https://redeem.cashu.me' \
        -H 'Connection: keep-alive' \
        -H 'Sec-Fetch-Dest: empty' \
        -H 'Sec-Fetch-Mode: cors' \
        -H 'Sec-Fetch-Site: cross-site' \
        -H 'Sec-GPC: 1' \
        -H 'Priority: u=4' \
        -H 'TE: trailers' \
        --data-raw "{\"proofs\":[{\"secret\":\"$PROOF_SECRET\"}]}")
    
    if echo "$RESPONSE" | jq -e . >/dev/null 2>&1; then
        [ "$VERBOSE" = "true" ] && echo "Token check response: $RESPONSE"
        [ "$VERBOSE" = "true" ] && echo "Extracted proof secret: $PROOF_SECRET"
        [ "$VERBOSE" = "true" ] && echo "Extracted proof id: $PROOF_ID"
        [ "$VERBOSE" = "true" ] && echo "Extracted proof C: $PROOF_C"
    else
        echo "Error in token check response: $RESPONSE"
        exit 1
    fi
}

# Function to get lnurl payment request details and extract the amount
get_lnurl_details() {
    [ "$VERBOSE" = "true" ] && echo "Getting lnurl details..."
    LNURL_DETAILS=$(curl -s "$LNURL" \
        -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0' \
        -H 'Accept: */*' \
        -H 'Accept-Language: en-US,en;q=0.5' \
        -H 'Accept-Encoding: gzip, deflate, br, zstd' \
        -H 'Referer: https://redeem.cashu.me/' \
        -H 'Origin: https://redeem.cashu.me' \
        -H 'Connection: keep-alive' \
        -H 'Sec-Fetch-Dest: empty' \
        -H 'Sec-Fetch-Mode: cors' \
        -H 'Sec-Fetch-Site: cross-site' \
        -H 'Sec-GPC: 1' \
        -H 'Priority: u=1')
    if echo "$LNURL_DETAILS" | jq -e . >/dev/null 2>&1; then
        LNURL_AMOUNT=$(echo $LNURL_DETAILS | jq -r '.maxSendable')
        [ "$VERBOSE" = "true" ] && echo "LNURL details: $LNURL_DETAILS"
        [ "$VERBOSE" = "true" ] && echo "Extracted lnurl amount: $LNURL_AMOUNT"
    else
        echo "Error in lnurl details response: $LNURL_DETAILS"
        exit 1
    fi
}

# Function to get the payment request for a specific amount
get_payment_request() {
    [ "$VERBOSE" = "true" ] && echo "Getting payment request for amount $TOTAL_AMOUNT..."
    PAYMENT_REQUEST=$(curl -s "$LNURL?amount=$((TOTAL_AMOUNT * 1000))" \
        -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0' \
        -H 'Accept: */*' \
        -H 'Accept-Language: en-US,en;q=0.5' \
        -H 'Accept-Encoding: gzip, deflate, br, zstd' \
        -H 'Referer: https://redeem.cashu.me/' \
        -H 'Origin: https://redeem.cashu.me' \
        -H 'Connection: keep-alive' \
        -H 'Sec-Fetch-Dest: empty' \
        -H 'Sec-Fetch-Mode: cors' \
        -H 'Sec-Fetch-Site: cross-site' \
        -H 'Sec-GPC: 1' \
        -H 'Priority: u=4' \
        -H 'TE: trailers')
    PAYMENT_REQUEST=$(echo $PAYMENT_REQUEST | jq -r '.pr')
    [ "$VERBOSE" = "true" ] && echo "Payment request response: $PAYMENT_REQUEST"
}

# Function to check fees for the payment request
check_fees() {
    [ "$VERBOSE" = "true" ] && echo "Checking fees for the payment request..."
    RESPONSE=$(curl -s -X POST "$MINT_URL/checkfees" \
        -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0' \
        -H 'Accept: application/json, text/plain, */*' \
        -H 'Accept-Language: en-US,en;q=0.5' \
        -H 'Accept-Encoding: gzip, deflate, br, zstd' \
        -H 'Referer: https://redeem.cashu.me/' \
        -H 'Content-Type: application/json' \
        -H 'Origin: https://redeem.cashu.me' \
        -H 'Connection: keep-alive' \
        -H 'Sec-Fetch-Dest: empty' \
        -H 'Sec-Fetch-Mode: cors' \
        -H 'Sec-Fetch-Site: cross-site' \
        -H 'Sec-GPC: 1' \
        -H 'Priority: u=4' \
        -H 'TE: trailers' \
        --data-raw "{\"pr\":\"$PAYMENT_REQUEST\"}")
    [ "$VERBOSE" = "true" ] && echo "Check fees response: $RESPONSE"
}

# Function to redeem the token
redeem_token() {
  [ "$VERBOSE" = "true" ] && echo "Redeeming token..."
  
  # Capture the response without any prefix
  RESPONSE=$(curl -s -X POST "$MINT_URL/melt" \
    -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0' \
    -H 'Accept: application/json, text/plain, */*' \
    -H 'Accept-Language: en-US,en;q=0.5' \
    -H 'Accept-Encoding: gzip, deflate, br, zstd' \
    -H 'Referer: https://redeem.cashu.me/' \
    -H 'Content-Type: application/json' \
    -H 'Origin: https://redeem.cashu.me' \
    -H 'Connection: keep-alive' \
    -H 'Sec-Fetch-Dest: empty' \
    -H 'Sec-Fetch-Mode: cors' \
    -H 'Sec-Fetch-Site: cross-site' \
    -H 'Sec-GPC: 1' \
    -H 'Priority: u=4' \
    -H 'TE: trailers' \
    --data-raw "{\"pr\":\"$PAYMENT_REQUEST\",\"proofs\":$PROOFS_JSON,\"outputs\":[], \"paid_amount\": $TOTAL_AMOUNT}")

  # Modify the response JSON to ensure total_amount is treated as an integer
  MODIFIED_RESPONSE=$(echo "$RESPONSE" | jq --argjson total_amount "$TOTAL_AMOUNT" '. + {total_amount: $total_amount}')

  log_message "Redeem token response: $MODIFIED_RESPONSE"
  echo $MODIFIED_RESPONSE
}


# Check if file path and LNURL are provided
if [ -z "$TOKEN_FILE" ] || [ -z "$RECIPIENT_LNURL" ]; then
    echo "Usage: $0 <token_file_path> <username@domain>"
    exit 1
fi

log_message "Curl request - Token file: $TOKEN_FILE"
log_message "Curl request - Recipient LNURL: $RECIPIENT_LNURL"

# Call the check_dependencies function right after defining it
check_dependencies

# Generate MINT_URL and LNURL
generate_urls

# Read token from file
read_token_from_file

# Check if token is provided
if [ -z "$TOKEN" ]; then
  echo "Error: Token is empty."
  exit 1
fi


log_message "Curl request - ECASH: $TOKEN"

# Decode the token
decode_token

# Execute the sequence of requests
get_mint_keys
check_token
get_lnurl_details
get_payment_request
check_fees
redeem_token

