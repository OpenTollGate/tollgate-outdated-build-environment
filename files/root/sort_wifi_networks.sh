#!/bin/sh

# Sort the networks by signal in descending order
sort_networks_by_signal_desc() {
    local json_input="$1"
    echo "$json_input" | jq -r '
        map(.signal |= tonumber) |
        sort_by(-.signal)
    '
}

# Remove JSON tuples with empty SSIDs
remove_empty_ssids() {
    local json_input="$1"
    echo "$json_input" | jq -r '
        map(select(.ssid != ""))
    '
}

# Remove duplicate SSIDs, keeping the first instance (strongest signal already first after sort)
remove_duplicate_ssids() {
    local json_input="$1"
    echo "$json_input" | jq -r '
        reduce .[] as $item ({}; 
            if .[$item.ssid] == null then . + { ($item.ssid): $item } else . end
        ) | [.[]]
    '
}

# Capture, sort, and display the full JSON data
sort_and_display_full_json() {
    local scan_script_output
    scan_script_output=$(./scan_wifi_networks.sh)

    if [ $? -eq 0 ] && echo "$scan_script_output" | jq empty 2>/dev/null; then
        local filtered_json
        filtered_json=$(remove_empty_ssids "$scan_script_output")
        
        local sorted_json
        sorted_json=$(sort_networks_by_signal_desc "$filtered_json")
        local removed_duplicates
        removed_duplicates=$(remove_duplicate_ssids "$sorted_json")
        
        echo "$removed_duplicates"
    else
        echo "Failed to obtain or parse Wi-Fi scan results" >&2
        return 1
    fi
}

# Function to select an SSID from the list and return the associated JSON tuple
select_ssid() {
    local sorted_json
    sorted_json=$(sort_and_display_full_json)

    if [ $? -ne 0 ]; then
        return 1
    fi

    # Store the full JSON for later use
    echo "$sorted_json" > /tmp/networks.json

    echo "Available SSIDs:"
    # Use jq to number and display the SSIDs
    echo "$sorted_json" | jq -r 'to_entries | .[] | "\(.key + 1)) \(.value.ssid)"'

    local num_networks
    num_networks=$(echo "$sorted_json" | jq length)

    while true; do
        read -p "Enter the number of the SSID you want to connect to: " selection
        if [ "$selection" -ge 1 ] 2>/dev/null && [ "$selection" -le "$num_networks" ]; then
            # Use jq to get the selected network (array is 0-based, so subtract 1 from selection)
            local index=$((selection - 1))
            selected_json=$(echo "$sorted_json" | jq ".[$index]")
            selected_ssid=$(echo "$selected_json" | jq -r '.ssid')
            echo "You selected SSID: $selected_ssid"
            
            # Write the selected JSON tuple to /tmp/selected_ssid.md
            echo "$selected_json" > /tmp/selected_ssid.md
            echo "Selected SSID details saved to /tmp/selected_ssid.md"
            
            return 0
        else
            echo "Invalid selection. Please enter a number between 1 and $num_networks."
        fi
    done
}

main() {
    case $1 in
        --full-json)
            sort_and_display_full_json
            ;;
        --ssid-list)
            local sorted_json
            sorted_json=$(sort_and_display_full_json)
            echo "$sorted_json" | jq -r '.[] | .ssid'
            ;;
        --select-ssid)
            select_ssid
            ;;
        *)
            echo "Usage: $0 [--full-json | --ssid-list | --select-ssid]"
            return 1
            ;;
    esac
}

main "$@"
