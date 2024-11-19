#!/bin/sh

# Function to convert BTC price to SATs per dollar
calculate_sats_per_dollar() {
    btc_price=$1
    sats_per_btc=100000000
    echo "$sats_per_btc $btc_price" | awk '{printf "%.8f", $1/$2}'
}

# Try CoinGecko
price=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd" | jq -r '.bitcoin.usd' 2>/dev/null)
case "$price" in
    ''|*[!0-9.]*) ;; # invalid price
    *)
        sats_per_dollar=$(calculate_sats_per_dollar "$price")
        echo "$sats_per_dollar" > /tmp/moscow_time.json
        exit 0
        ;;
esac

# Try Coinbase
price=$(curl -s "https://api.coinbase.com/v2/prices/BTC-USD/spot" | jq -r '.data.amount' 2>/dev/null)
case "$price" in
    ''|*[!0-9.]*) ;; # invalid price
    *)
        sats_per_dollar=$(calculate_sats_per_dollar "$price")
        echo "$sats_per_dollar" > /tmp/moscow_time.json
        exit 0
        ;;
esac

# Try Binance
price=$(curl -s "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT" | jq -r '.price' 2>/dev/null)
case "$price" in
    ''|*[!0-9.]*) ;; # invalid price
    *)
        sats_per_dollar=$(calculate_sats_per_dollar "$price")
        echo "$sats_per_dollar" > /tmp/moscow_time.json
        exit 0
        ;;
esac

echo "Failed to get price from any endpoint" >&2
exit 1
