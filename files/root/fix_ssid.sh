#!/bin/sh

# Function to get the hotspot SSID
get_hotspot_ssid() {
    if [ -f "/nostr/shell/nostr_keys.json" ]; then
        npub=$(jq -r ".npub_hex" /nostr/shell/nostr_keys.json 2>/dev/null)
        if [ -n "$npub" ] && [ "$npub" != "null" ]; then
            echo "TollGate_${npub:0:8}"
            return
        fi
    fi
    
    # Fallback to MAC address if npub is not available
    mac_address=$(cat /sys/class/ieee80211/phy0/macaddress | sed "s/://g")
    echo "TollGate_${mac_address}"
}

hotspot_ssid=$(get_hotspot_ssid)

uci set wireless.default_radio0.ssid="$hotspot_ssid"
uci set system.@system[0].hostname="$hotspot_ssid"
uci commit system
uci commit wireless
/etc/init.d/system reload
/sbin/wifi reload
