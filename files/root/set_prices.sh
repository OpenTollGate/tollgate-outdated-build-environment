#!/bin/sh

# Define JSON file path
JSON_FILE="/root/user_inputs.json"

# Debug function
debug_json() {
    echo "Current JSON content:" >> /tmp/debug_json.md
    cat "$JSON_FILE" >> /tmp/debug_json.md
    echo "JSON file size: $(wc -c < "$JSON_FILE") bytes" >> /tmp/debug_json.md
    echo "JSON file permissions: $(ls -l "$JSON_FILE")" >> /tmp/debug_json.md
}

# Ensure valid initial JSON exists
if [ ! -f "$JSON_FILE" ] || [ ! -s "$JSON_FILE" ]; then
    echo '{"authorized_clients": 0, "current_price": 1}' > "$JSON_FILE"
    chmod 644 "$JSON_FILE"
fi

# Debug before operations
echo "Before operations:" >> /tmp/debug_json.md
debug_json

# First, update the number of authorized clients
/root/number_of_authorized_clients.sh

# Read the number of authorized clients from the JSON
authorized_clients=$(jq -r '.authorized_clients // 0' "$JSON_FILE")
if [ -z "$authorized_clients" ] || [ "$authorized_clients" = "null" ]; then
    authorized_clients=0
fi

# Calculate the price: 2^(number of authorized clients)
price=$((2**authorized_clients))

# Create a properly formatted JSON update
TMP_FILE="${JSON_FILE}.tmp"

# Write to temporary file first, then validate it's proper JSON
echo "{\"authorized_clients\": $authorized_clients, \"current_price\": $price}" > "$TMP_FILE"

# Validate the temporary file
if jq '.' "$TMP_FILE" >/dev/null 2>&1; then
    mv "$TMP_FILE" "$JSON_FILE"
    chmod 644 "$JSON_FILE"
else
    echo "Error: Invalid JSON generated"
    echo "Temporary file content:"
    cat "$TMP_FILE"
    rm "$TMP_FILE"
    exit 1
fi

# Debug after operations
echo "After operations:" >> /tmp/debug_json.md
debug_json

echo "Updated price to $price sats based on $authorized_clients authorized clients"
