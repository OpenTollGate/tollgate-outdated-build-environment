#!/bin/sh

# if [ ! -f /tmp/moscow_time.json ]; then
#     /root/./get_moscow_time.sh
# fi

/root/./get_moscow_time.sh

# Read values from files
fiat_price=$(jq -r '.fiat_price' /root/user_inputs.json)
sats_per_dollar=$(jq -r '.sats_per_dollar' /tmp/moscow_time.json)

# Calculate values using awk instead of bc
sats_per_gb=$(awk "BEGIN {print $fiat_price * $sats_per_dollar}")
sats_per_mb=$(awk "BEGIN {print $sats_per_gb / 1024}")
mb_per_sat=$(awk "BEGIN {print 1 / $sats_per_mb}")

# Create JSON output
cat << EOF
{
  "sats_per_gb": $(printf "%.8f" $sats_per_gb),
  "sats_per_mb": $(printf "%.8f" $sats_per_mb),
  "mb_per_sat": $(printf "%.8f" $mb_per_sat)
}
EOF
