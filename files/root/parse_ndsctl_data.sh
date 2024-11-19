#!/bin/sh
# calculate_metrics.sh

JSON_FILE="/tmp/pricing_inputs.json"

# Check if file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: $JSON_FILE not found"
    exit 1
fi

# Get current timestamp
CURRENT_TIME=$(date +%s)

# Function to calculate total downloads
get_total_downloads() {
    jq '
        [
            .clients[] 
            | select(.state != "Preauthenticated") 
            | (.download_this_session | tonumber)
        ] | add // 0
    ' "$JSON_FILE"
}

# Function to calculate total uploads
get_total_uploads() {
    jq '
        [
            .clients[] 
            | select(.state != "Preauthenticated") 
            | (.upload_this_session | tonumber)
        ] | add // 0
    ' "$JSON_FILE"
}

# Function to count authorized clients
get_authorized_clients() {
    jq '
        [
            .clients[] 
            | select(.state != "Preauthenticated")
        ] | length
    ' "$JSON_FILE"
}

# Function to get detailed client information
get_client_details() {
    jq -r --arg current_time "$CURRENT_TIME" '
        .clients 
        | to_entries
        | .[]
        | .value
        | . as $client
        | (
            if (.session_end != "null" and .session_start != "null") then
                ((.session_end | tonumber) - (.session_start | tonumber))
            else
                0
            end
        ) as $remaining_session_time
        | (
            if (.last_active != "null") then
                ($current_time | tonumber) - (.last_active | tonumber)
            else
                0
            end
        ) as $time_since_last_active
        | (
            if (.download_quota != "null" and .download_this_session != "null") then
                (.download_quota | tonumber) - (.download_this_session | tonumber)
            else
                0
            end
        ) as $remaining_download_quota
        | (
            if (.upload_quota != "null" and .upload_this_session != "null") then
                (.upload_quota | tonumber) - (.upload_this_session | tonumber)
            else
                0
            end
        ) as $remaining_upload_quota
        | (
            (.download_this_session | tonumber) + (.upload_this_session | tonumber)
        ) as $total_data_usage
        | "Client MAC: \(.mac)\n" +
          "  State: \(.state)\n" +
          "  Total Data Usage: \($total_data_usage) bytes\n" +
          "  Remaining Session Time: \($remaining_session_time) seconds\n" +
          "  Time Since Last Active: \($time_since_last_active) seconds\n" +
          "  Remaining Download Quota: \($remaining_download_quota) bytes\n" +
          "  Remaining Upload Quota: \($remaining_upload_quota) bytes\n" +
          "  Session: \(.token)\n" +
          "----------------------------------------"
    ' "$JSON_FILE"
}

# Print summary
echo "=== Network Usage Summary ==="
echo "Authorized Clients: $(get_authorized_clients)"
echo "Total Downloads: $(get_total_downloads) bytes"
echo "Total Uploads: $(get_total_uploads) bytes"
echo ""
echo "=== Detailed Client Information ==="
get_client_details


# Additional calculations if needed
# Get clients with low remaining quota (less than 1MB)
echo "=== Clients with Low Remaining Quota (<256MB) ==="
jq -r --arg current_time "$CURRENT_TIME" '
    .clients[]
    | select(
        (.download_quota != "null" and .download_this_session != "null") and
        ((.download_quota | tonumber) - (.download_this_session | tonumber)) < 268435456
    )
    | "MAC: \(.mac) - Remaining Download Quota: \((.download_quota | tonumber) - (.download_this_session | tonumber)) bytes"
' "$JSON_FILE"

# Get clients inactive for more than 1 hour (3600 seconds)
echo "=== Inactive Clients (>1 hour) ==="
jq -r --arg current_time "$CURRENT_TIME" '
    .clients[]
    | select(
        (.last_active != "null") and
        (($current_time | tonumber) - (.last_active | tonumber)) > 3600
    )
    | "MAC: \(.mac) - Inactive for: \(($current_time | tonumber) - (.last_active | tonumber)) seconds"
' "$JSON_FILE"

# Get clients active for less than 5 minutes (300 seconds)
echo "=== Active Clients (<5 minutes) ==="
jq -r --arg current_time "$CURRENT_TIME" '
    .clients[]
    | select(
        (.last_active != "null") and
        (($current_time | tonumber) - (.last_active | tonumber)) < 300
    )
    | "MAC: \(.mac) - Inactive for: \(($current_time | tonumber) - (.last_active | tonumber)) seconds"
' "$JSON_FILE"
