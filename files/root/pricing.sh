#!/bin/sh

# Check if argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <sats_paid>"
    exit 1
fi

# Read input values
SATS_PAID=$1
COST=$(jq -r '.cost' /root/user_inputs.json)
MARGINS=$(jq -r '.margins' /root/user_inputs.json)
CONTRIBUTION=$(jq -r '.contribution' /root/user_inputs.json)
SATS_PER_DOLLAR=$(jq -r '.sats_per_dollar' /tmp/moscow_time.json)

# Calculate fiat price with margins
FIAT_PRICE=$(awk "BEGIN {print $COST + ($COST * $MARGINS / 100)}")

# Calculate gigabytes allocation
GB_ALLOCATION=$(awk "BEGIN {print $SATS_PAID / $SATS_PER_DOLLAR / $FIAT_PRICE}")

# Calculate profit in sats
PROFIT=$(awk "BEGIN {print $SATS_PAID * $MARGINS / 100}")

# Calculate contribution amount
CONTRIBUTION_AMOUNT=$(awk "BEGIN {print $PROFIT * $CONTRIBUTION / 100}")

# Create JSON and save to file
jq -n \
    --arg fiat_price "$(printf "%.2f" $FIAT_PRICE)" \
    --arg gb_allocation "$(printf "%.4f" $GB_ALLOCATION)" \
    --arg profit "$(printf "%.0f" $PROFIT)" \
    --arg contribution "$(printf "%.0f" $CONTRIBUTION_AMOUNT)" \
    '{
        fiat_price: $fiat_price,
        gb_allocation: $gb_allocation,
        profit_sats: $profit,
        contribution_sats: $contribution
    }' > /tmp/stack_growth.json

# Print success message
echo "Calculations completed and saved to /tmp/stack_growth.json"
