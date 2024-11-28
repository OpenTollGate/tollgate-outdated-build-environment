#!/bin/sh

relay=$1
purser=$2

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Please provide relay and purser as arguemnts"
    exit 1
fi

echo "Relay: $relay"
echo "Purser: $purser"
# wss://tollbooth.stens.dev a057f743eca9efe9c97e6358bf2b37b05349029edfaa1a5e6e0c117fc95b9114

while :
do
    ./process_auth.sh $relay $purser
done
