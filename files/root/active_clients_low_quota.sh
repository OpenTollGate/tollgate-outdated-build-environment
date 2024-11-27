#!/bin/sh

JSON_FILE="/tmp/pricing_inputs.json"

/root/./save_ndsctl_data.sh

# Get current timestamp
CURRENT_TIME=$(date +%s)

# Print active clients (<5 mins) with low remaining quota (<256MB) in JSON format
jq --arg current_time "$CURRENT_TIME" '
{
    "active_clients_low_quota": [
        .clients[]
        | select(
            # Check if client is active (less than 5 minutes since last activity)
            (.last_active != "null") and
            (($current_time | tonumber) - (.last_active | tonumber)) < 300
            and
            # Check if quota is low (less than 256MB)
            (.download_quota != "null" and .download_this_session != "null" and .upload_this_session != "null") and
            ((.download_quota | tonumber) - ((.download_this_session | tonumber) + (.upload_this_session | tonumber))) < 262144
        )
        | {
            session_id: .token,
            mac_address: .mac,
            last_active_seconds: (($current_time | tonumber) - (.last_active | tonumber)),
            total_usage_kb: ((.download_this_session | tonumber) + (.upload_this_session | tonumber)),
            remaining_data_kb: ((.download_quota | tonumber) - ((.download_this_session | tonumber) + (.upload_this_session | tonumber))),
            ip_address: .ip,
            state: .state
        }
    ],
    "timestamp": ($current_time | tonumber)
}' "$JSON_FILE"
