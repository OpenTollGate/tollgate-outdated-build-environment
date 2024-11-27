#!/bin/sh

if [ $# -ne 1 ] || ! expr "$1" : '[0-9]\+$' >/dev/null; then
    echo "Please provide a single positive integer argument (kilobytes)"
    exit 1
fi

kb=$1
bytes=$((kb * 1024))
mb=$(awk "BEGIN {printf \"%.2f\", $kb/1024}")
gb=$(awk "BEGIN {printf \"%.2f\", $kb/1024/1024}")

# Determine the most appropriate unit
if [ $bytes -ge 1 ] && [ $bytes -lt 1024 ]; then
    selected="$bytes bytes"
elif [ $kb -ge 1 ] && [ $kb -lt 1024 ]; then
    selected="$kb kilobytes"
elif [ "$(awk "BEGIN {print ($mb >= 1 && $mb < 1024) ? 1 : 0}")" -eq 1 ]; then
    selected="$mb megabytes"
else
    selected="$gb gigabytes"
fi

cat << EOF
{
    "bytes": "$bytes bytes",
    "kilobytes": "$kb kilobytes",
    "megabytes": "$mb megabytes",
    "gigabytes": "$gb gigabytes",
    "select": "$selected"
}
EOF
