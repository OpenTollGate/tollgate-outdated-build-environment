#!/bin/bash

VPS_IP="78.47.249.97"

# Upload files
scp *.php ../../../files/cgi-bin/curl_request.sh root@${VPS_IP}:/var/www/fas-hid/.

# Run permission commands on remote server
ssh root@${VPS_IP} "
touch /tmp/arguments_log.md
chown www-data:www-data /tmp/arguments_log.md
chmod 666 /tmp/arguments_log.md
"
