#!/bin/sh

set -x
set -e

# Function to extract URL and fas parameter from the redirect
get_portal_params() {
    # Use curl with -L to follow redirects
    RESPONSE=$(curl -s -L http://status.client:2050)
    
    # Extract the portal URL from the final redirect location
    PORTAL_URL=$(echo "$RESPONSE" | grep -oP '(http|https)://[\w./?=-]*' | head -n 1)
    
    if [ -z "$PORTAL_URL" ]; then
        echo "Failed to extract portal URL. Response was: $RESPONSE"
        exit 1
    fi

    # Extract base URL and fas parameter
    BASE_URL=$(echo "$PORTAL_URL" | cut -d'?' -f1)
    FAS_PARAM=$(echo "$PORTAL_URL" | grep -o "fas=.*" | cut -d'=' -f2)

    # Get the form page to verify fas parameter
    FORM_PAGE=$(curl -s "$PORTAL_URL")
    
    # Extract fas value from the form (as a backup/verification)
    FORM_FAS=$(echo "$FORM_PAGE" | grep -o 'name="fas" value="[^"]*"' | cut -d'"' -f4)
    
    # Use form fas if available, otherwise use the one from URL
    if [ ! -z "$FORM_FAS" ]; then
        FAS_PARAM="$FORM_FAS"
    fi
    
    # Export variables for use in main script
    export PORTAL_URL="$BASE_URL"
    export FAS_PARAM="$FAS_PARAM"
}

# Check if voucher code is provided
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
sleep 2

# Test internet connectivity
echo "Testing internet connectivity..."
curl -I http://detectportal.firefox.com/canonical.html

# Additional connectivity test
echo "Testing ping to 8.8.8.8..."
ping -c 4 8.8.8.8
