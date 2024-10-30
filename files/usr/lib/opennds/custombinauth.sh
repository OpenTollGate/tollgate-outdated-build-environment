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

#!/bin/sh

if [ $action = "auth_client" ]; then
    # Get custom data (amount paid)
    custom=$7
    decoded=$(ndsctl b64decode "$custom")
    
    # Extract amount from the decoded string
    amount=$(echo "$decoded" | grep -o 'amount=[0-9]*' | cut -d'=' -f2)
    
    if [ -n "$amount" ]; then
        # Convert amount (sats) to minutes, then to seconds
        session_length=$((amount * 60))
        
        # Log the calculation
        logger "OpenNDS: Amount paid: $amount sats, Session length: $session_length seconds"
    else
        # Default to 1 hour if no amount specified
        session_length=3600
        logger "OpenNDS: No amount specified, defaulting to 1 hour session"
    fi
    
    # Set other parameters ( optional)
    upload_rate=0
    download_rate=0
    upload_quota=0
    download_quota=0
    exitlevel=0
fi
