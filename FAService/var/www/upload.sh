#!/bin/bash

VPS_IP="78.47.249.97"
ROUTER_IP="192.168.8.1"

# Upload files to FAS server (VPS)
scp *.php ../../../files/cgi-bin/curl_request.sh root@${VPS_IP}:/var/www/fas-hid/.

# Run permission commands on remote server
ssh root@${VPS_IP} "
sudo apt install -y jq
touch /tmp/arguments_log.md
chown www-data:www-data /tmp/arguments_log.md
chmod 777 /tmp/arguments_log.md
"

# Upload files to OpenWRT router
scp ../../../files/etc/config/opennds root@${ROUTER_IP}:/etc/config/opennds
scp ../../../files/etc/config/firewall root@${ROUTER_IP}:/etc/config/firewall
scp ../../../files/usr/lib/opennds/custombinauth.sh root@${ROUTER_IP}:/usr/lib/opennds/custombinauth.sh
scp ../../../files/usr/lib/opennds/binauth_log.sh root@${ROUTER_IP}:/usr/lib/opennds/binauth_log.sh
scp ../../../files/usr/lib/opennds/client_params.sh root@${ROUTER_IP}:/usr/lib/opennds/client_params.sh

# Set permissions and restart services on router
ssh root@${ROUTER_IP} "
chmod +x /usr/lib/opennds/custombinauth.sh
chmod +x /usr/lib/opennds/binauth_log.sh
chmod +x /usr/lib/opennds/client_params.sh
reboot
"
