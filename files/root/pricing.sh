#!/bin/sh

# Check if both arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <sats_paid> <note_hash>"
    exit 1
fi

# Read input values
SATS_PAID=$1
NOTE_HASH=$2
FIAT_PRICE=$(jq -r '.fiat_price' /root/user_inputs.json)
MARGINS=$(jq -r '.margins' /root/user_inputs.json)
CONTRIBUTION=$(jq -r '.contribution' /root/user_inputs.json)
SATS_PER_DOLLAR=$(jq -r '.sats_per_dollar' /tmp/moscow_time.json)

# Calculate gigabytes allocation
GB_ALLOCATION=$(awk "BEGIN {print $SATS_PAID / $SATS_PER_DOLLAR / $FIAT_PRICE}")

# Calculate profit in sats
PROFIT=$(awk "BEGIN {print $SATS_PAID * $MARGINS / 100}")

# Calculate contribution amount
CONTRIBUTION_AMOUNT=$(awk "BEGIN {print $PROFIT * $CONTRIBUTION / 100}")

# Create JSON with only transaction-specific values
jq -n \
    --arg sats_paid "$SATS_PAID" \
    --arg gb_allocation "$(printf "%.4f" $GB_ALLOCATION)" \
    --arg profit "$(printf "%.0f" $PROFIT)" \
    --arg contribution "$(printf "%.0f" $CONTRIBUTION_AMOUNT)" \
    '{
        gb_allocation: $gb_allocation,
        mb_allocation: ($gb_allocation | tonumber * 1024),
        kb_allocation: ($gb_allocation | tonumber * 1048576 | round),
        sats_paid: $sats_paid,
        profit_sats: $profit,
        contribution_sats: $contribution
    }' > "/tmp/stack_growth_${NOTE_HASH}.json"

# Print success message
# echo "Calculations completed and saved to /tmp/stack_growth_${NOTE_HASH}.json"
