#!/bin/sh

# Check internet connectivity first
if ! ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
    echo "Router appears to be offline - skipping price update" >&2
    exit 1
fi

# Function to convert BTC price to SATs per dollar
calculate_sats_per_dollar() {
    btc_price=$1
    sats_per_btc=100000000
    echo "$sats_per_btc $btc_price" | awk '{printf "%.8f", $1/$2}'
}

# Function to save results in JSON format
save_json() {
    btc_price=$1
    sats_per_dollar=$2
    sats_per_dollar_db=$(./decibel.sh $sats_per_dollar)
    echo "{\"btc_price\": $btc_price, \"sats_per_dollar\": $sats_per_dollar, \"sats_per_dollar_db\": $sats_per_dollar_db}" | jq > /tmp/moscow_time.json
    /root/./set_vendor_elements.sh 212121 01
}

# Add timeout to curl calls
CURL_OPTS="-s --connect-timeout 5 --max-time 10"

# Try CoinGecko
price=$(curl $CURL_OPTS "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd" | jq -r '.bitcoin.usd' 2>/dev/null)
case "$price" in
    ''|*[!0-9.]*) ;; # invalid price
    *)
        sats_per_dollar=$(calculate_sats_per_dollar "$price")
        save_json "$price" "$sats_per_dollar"
        exit 0
        ;;
esac

# Try Coinbase
price=$(curl $CURL_OPTS "https://api.coinbase.com/v2/prices/BTC-USD/spot" | jq -r '.data.amount' 2>/dev/null)
case "$price" in
    ''|*[!0-9.]*) ;; # invalid price
    *)
        sats_per_dollar=$(calculate_sats_per_dollar "$price")
        save_json "$price" "$sats_per_dollar"
        exit 0
        ;;
esac

# Try Binance
price=$(curl $CURL_OPTS "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT" | jq -r '.price' 2>/dev/null)
case "$price" in
    ''|*[!0-9.]*) ;; # invalid price
    *)
        sats_per_dollar=$(calculate_sats_per_dollar "$price")
        save_json "$price" "$sats_per_dollar"
        exit 0
        ;;
esac

echo "Failed to get price from any endpoint" >&2
exit 1
