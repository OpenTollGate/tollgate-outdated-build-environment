#!/bin/sh

set -x
set -e

# Function to extract URL and fas parameter from the redirect
get_portal_params() {
    # Use curl with -L to follow redirects
    RESPONSE=$(curl -s -L http://status.client:2050)
    
    # Extract the portal URL from an <form> action or <a href> tag
    # It's important to find the appropriate place/construct to fetch the URL from
    PORTAL_URL=$(echo "$RESPONSE" | grep -oP 'action="(/opennds_preauth/)".*' | sed -n 's/.*action="$[^"]*$".*/http:\/\/status.client\1/p')
    
    if [ -z "$PORTAL_URL" ]; then
        echo "Failed to extract portal URL. Response was: $RESPONSE"
        exit 1
    fi

    # Extract the 'fas' parameter from hidden input field
    FAS_PARAM=$(echo "$RESPONSE" | grep -oP 'name="fas" value="[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$FAS_PARAM" ]; then
        echo "Fas parameter extraction failed"
        exit 1
    fi

    # Export variables for use in main script
    export PORTAL_URL
    export FAS_PARAM
}

# Check if a voucher code is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <voucher_code>"
    exit 1
fi

VOUCHER_CODE="$1"

# Get portal parameters
echo "Extracting portal parameters..."
get_portal_params

# Verify we have the required parameters
if [ -z "$PORTAL_URL" ] || [ -z "$FAS_PARAM" ]; then
    echo "Failed to extract required parameters"
    exit 1
fi

echo "Portal URL: $PORTAL_URL"
echo "FAS Parameter extracted"

# Submit the form using GET request
echo "Submitting voucher code: $VOUCHER_CODE"
ENCODED_URL="${PORTAL_URL}?fas=${FAS_PARAM}&tos=accepted&voucher=${VOUCHER_CODE}"
curl -v "$ENCODED_URL"

# Wait a moment for the connection to establish
sleep 5

# Test internet connectivity
echo "Testing internet connectivity..."
curl -I http://detectportal.firefox.com/canonical.html

# Additional connectivity test
echo "Testing ping to 8.8.8.8..."
ping -c 4 8.8.8.8
