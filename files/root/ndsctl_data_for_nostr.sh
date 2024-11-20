#!/bin/sh

JSON_FILE="/tmp/pricing_inputs.json"
/root/./save_ndsctl_data.sh

# Check if file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "{\"error\": \"$JSON_FILE not found\"}"
    exit 1
fi

# Get current timestamp
CURRENT_TIME=$(date +%s)

# Generate complete JSON output
jq --arg current_time "$CURRENT_TIME" '
{
    "timestamp": ($current_time | tonumber),
    "network_summary": {
        "authorized_clients": ([.clients[] | select(.state != "Preauthenticated")] | length),
        "total_downloads": ([.clients[] | select(.state != "Preauthenticated") | (.download_this_session | tonumber)] | add // 0),
        "total_uploads": ([.clients[] | select(.state != "Preauthenticated") | (.upload_this_session | tonumber)] | add // 0),
        "total_remaining_data": ([.clients[] | 
            select(.download_quota != "null") | 
            (.download_quota | tonumber) - ((.download_this_session | tonumber) + (.upload_this_session | tonumber))
        ] | add // 0)
    },
    "client_details": [
        .clients[] | 
        . as $client |
        {
            "state": .state,
            "session_id": .token,
            "total_data_usage": ((.download_this_session | tonumber) + (.upload_this_session | tonumber)),
            "remaining_data": (
                if (.download_quota != "null") then
                    (.download_quota | tonumber) - ((.download_this_session | tonumber) + (.upload_this_session | tonumber))
                else
                    0
                end
            ),
            "remaining_session_time": (
                if (.session_end != "null") then
                    ((.session_end | tonumber) - ($current_time | tonumber))
                else
                    0
                end
            ),
            "time_since_last_active": (
                if (.last_active != "null") then
                    ($current_time | tonumber) - (.last_active | tonumber)
                else
                    0
                end
            )
        }
    ],
    "low_quota_clients": [
        .clients[] |
        select(
            (.download_quota != "null" and .download_this_session != "null" and .upload_this_session != "null") and
            ((.download_quota | tonumber) - ((.download_this_session | tonumber) + (.upload_this_session | tonumber))) < 262144
        ) |
        {
            "session_id": .token,
            "remaining_data": ((.download_quota | tonumber) - ((.download_this_session | tonumber) + (.upload_this_session | tonumber)))
        }
    ],
    "inactive_clients": [
        .clients[] |
        select(
            (.last_active != "null") and
            (($current_time | tonumber) - (.last_active | tonumber)) > 3600
        ) |
        {
            "session_id": .token,
            "inactive_time": (($current_time | tonumber) - (.last_active | tonumber))
        }
    ],
    "active_clients": [
        .clients[] |
        select(
            (.last_active != "null") and
            (($current_time | tonumber) - (.last_active | tonumber)) < 300
        ) |
        {
            "session_id": .token,
            "last_active_seconds": (($current_time | tonumber) - (.last_active | tonumber))
        }
    ]
}' "$JSON_FILE"

# ndsctl auth [mac address] 1440 0 0 1000000 1000000 na
