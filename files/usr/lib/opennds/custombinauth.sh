#!/bin/sh
#Copyright (C) The openNDS Contributors 2004-2022
#Copyright (C) BlueWave Projects and Services 2015-2023
#This software is released under the GNU GPL license.

# This is a stub for a custom binauth script
# It is included by the default binauth_log.sh script when it runs
#
# This included script can override:
# exitlevel, session length, upload rate, download rate, upload quota and download quota.

# Add custom code after this line:

log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp: $1" >> /tmp/custombinauth.log
}

log_message "=== New Authentication Request ==="
log_message "Action: $action"

if [ $action = "auth_client" ]; then
    # Log raw custom data
    log_message "Raw custom data: $7"
    
    # Get custom data (amount paid)
    custom=$7
    decoded=$(ndsctl b64decode "$custom")
    log_message "Decoded custom data: $decoded"
    
    # Extract amount from the decoded string
    amount=$(echo "$decoded" | grep -o 'amount=[0-9]*' | cut -d'=' -f2)
    log_message "Extracted amount: $amount"
    
    if [ -n "$amount" ]; then
        # Convert amount (sats) to minutes, then to seconds
        session_length=$((amount *  60))
        log_message "Amount paid: $amount sats"
        log_message "Session length: $session_length seconds (${amount} minutes)"
        
        # Log to system log as well
        logger "OpenNDS: Amount paid: $amount sats, Session length: $session_length seconds"
    else
        # Default to 1 hour if no amount specified
        session_length=3600
        log_message "No amount specified, defaulting to 1 hour session"
        logger "OpenNDS: No amount specified, defaulting to 1 hour session"
    fi
    
    # Set other parameters (optional)
    upload_rate=0
    download_rate=0
    upload_quota=0
    download_quota=0
    exitlevel=0
    
    # Log final parameters
    log_message "Final parameters:"
    log_message "- Session length: $session_length seconds"
    log_message "- Upload rate: $upload_rate kb/s"
    log_message "- Download rate: $download_rate kb/s"
    log_message "- Upload quota: $upload_quota kB"
    log_message "- Download quota: $download_quota kB"
    log_message "- Exit level: $exitlevel"
fi

log_message "=== End of Authentication Request ==="
log_message ""
