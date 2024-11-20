#!/bin/sh
# save_ndsctl_data.sh

# Define JSON file path
JSON_FILE="/tmp/pricing_inputs.json"

# Debug function
debug_json() {
    echo "Current JSON content:" >> /tmp/debug_json.md
    cat "$JSON_FILE" >> /tmp/debug_json.md
    echo "JSON file size: $(wc -c < "$JSON_FILE") bytes" >> /tmp/debug_json.md
    echo "JSON file permissions: $(ls -l "$JSON_FILE")" >> /tmp/debug_json.md
}

# Get ndsctl output and save it
ndsctl json > "$JSON_FILE"
chmod 644 "$JSON_FILE"

# Debug after save
# echo "After save:"
# debug_json
