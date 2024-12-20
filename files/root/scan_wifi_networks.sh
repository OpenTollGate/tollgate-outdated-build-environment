#!/bin/sh

get_wifi_interface() {
    iw dev | awk '$1 == "Interface" { iface=$2 } $1 == "type" && $2 == "managed" { print iface; exit }'
}

scan_wifi_networks_to_json() {
    local interface=$(get_wifi_interface)

    if [ -z "$interface" ]; then
        echo "No managed Wi-Fi interface found" >&2
        return 1
    fi

    ip link set "$interface" up

    scan_result=$(iw dev "$interface" scan 2>&1)

    if echo "$scan_result" | grep -q "Resource busy"; then
        echo "Resource busy" >&2
        return 2
    fi

    echo "$scan_result" | awk -v parse_cmd="$0" '
        function escape_json_string(str) {
            gsub(/["\\]/, "\\\\&", str)
            gsub(/\n/, "\\n", str)
            gsub(/\r/, "\\r", str)
            gsub(/\t/, "\\t", str)
            gsub(/[\b]/, "\\b", str)
            gsub(/[\f]/, "\\f", str)
            return str
        }

        BEGIN {
            print "["
            first = 1
        }
        $1 == "BSS" {
            # If previous BSS has valid data, print it
            if (mac != "" && ssid != "") {
                if (!first) print ","
                printf "  {\"mac\": \"%s\", \"ssid\": \"%s\", \"encryption\": \"%s\", \"signal\": %s", \
                    mac, escape_json_string(ssid), encryption, signal

                # Add vendor elements for TollGate SSIDs

if (ssid ~ /^TollGate_/) {
    cmd = "/root/get_vendor_elements.sh \"" ssid "\" 12 | jq -r \".kb_allocation_decimal, .contribution_decimal\""
    if ((cmd | getline kb_allocation_decimal) > 0) {
        if ((cmd | getline contribution_decimal) > 0) {
            # Get decibel values using decibel.sh
            cmd_db1 = "/root/decibel.sh " kb_allocation_decimal
            cmd_db2 = "/root/decibel.sh " contribution_decimal
            
            cmd_db1 | getline kb_allocation_db
            cmd_db2 | getline contribution_db
            
            # Calculate score by adding the decibel values
            score = signal + kb_allocation_db + contribution_db
            
            printf ", \"kb_allocation_dB\": \"%s\", \"contribution_dB\": \"%s\", \"score\": \"%s\"", \
                  kb_allocation_db, contribution_db, score
                  
            close(cmd_db1)
            close(cmd_db2)
        }
    }
    close(cmd)
} else {
    # For non-TollGate SSIDs, score is just the signal value
    printf ", \"score\": \"%s\"", signal
}
                printf "}"
                first = 0
            }
            # Initialize for the new BSS
            mac = substr($2, 1, index($2, "(") - 1)
            ssid = ""
            encryption = "Open"
            signal = ""
        }
        $1 == "SSID:" {
            if (NF >= 2) {
                ssid = substr($0, index($0, $2))
            } else {
                ssid = ""
            }
        }
        /RSN:/ { encryption = "WPA2" }
        /WPA:/ { encryption = "WPA" }
        $1 == "signal:" {
            signal = $2
            sub(/ dBm$/, "", signal)
        }
        END {
            if (mac != "" && ssid != "") {
                if (!first) print ","
                printf "  {\"mac\": \"%s\", \"ssid\": \"%s\", \"encryption\": \"%s\", \"signal\": %s", \
                    mac, escape_json_string(ssid), encryption, signal

                if (ssid ~ /^TollGate_/) {
                    cmd = "/root/get_vendor_elements.sh \"" ssid "\" 12 | jq -r \".kb_allocation_decimal, .contribution_decimal\""
                    if ((cmd | getline kb_allocation_decimal) > 0) {
                        if ((cmd | getline contribution_decimal) > 0) {
                            # Get decibel values using decibel.sh
                            cmd_db1 = "/root/decibel.sh " kb_allocation_decimal
                            cmd_db2 = "/root/decibel.sh " contribution_decimal
                            
                            cmd_db1 | getline kb_allocation_db
                            cmd_db2 | getline contribution_db
                            
                            # First occurrence (in the BSS block):
                            printf ", \"kb_allocation_dB\": \"%s\", \"contribution_dB\": \"%s\"", \
                                  kb_allocation_db, contribution_db
                                  
                            close(cmd_db1)
                            close(cmd_db2)
                        }
                    }
                    close(cmd)
                }
                printf "}"
            }
            print "\n]"
        }
    ' | jq .
}

# Rest of the script remains the same
if ! command -v jq &>/dev/null; then
    echo "jq command not found, please install jq to use this script" >&2
    exit 1
fi

scan_until_success() {
    local output
    local retries=15
    local delay=3

    for i in $(seq 1 $retries); do
        output=$(scan_wifi_networks_to_json)
        ret_code=$?

        if [ $ret_code -eq 0 ]; then
            # Check if JSON output is valid
            if echo "$output" | jq empty 2>/dev/null; then
                echo "$output" | jq '.'
                return 0
            else
                echo "Invalid JSON output, retrying..." >&2
            fi
        elif [ $ret_code -eq 2 ]; then
            echo "Resource busy, retrying in $delay second(s)... ($i/$retries)" >&2
        else
            echo "Scan failed, retrying in $delay second(s)... ($i/$retries)" >&2
        fi

        sleep $delay
    done

    echo "Failed to scan Wi-Fi networks after $retries attempts" >&2
    return 1
}

scan_until_success
