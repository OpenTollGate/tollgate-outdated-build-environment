#!/bin/sh

# FAS Server details
FAS_IP="78.47.249.97"
FAS_PORT="80"
ROUTER_IP="192.168.8.1"

# In configure_fas.sh
# OpenNDS Walled Garden - expanded version
uci add_list opennds.@opennds[0].walledgarden="$FAS_IP"
uci add_list opennds.@opennds[0].walledgarden="$FAS_IP:$FAS_PORT"
uci add_list opennds.@opennds[0].walledgarden="$FAS_IP/fas-hid_cashu.php"
uci add_list opennds.@opennds[0].walledgarden="static.97.249.47.78.clients.your-server.de"
uci add_list opennds.@opennds[0].walledgarden="allow_all_x_requested_with"

# Add DNS entries for status client and FAS
uci add_list dhcp.@dnsmasq[0].address="/status.client/$ROUTER_IP"
uci add_list dhcp.@dnsmasq[0].address="/status.client/login/$ROUTER_IP"
uci add_list dhcp.@dnsmasq[0].server="$FAS_IP"
uci add_list dhcp.@dnsmasq[0].address="/fas-hid_cashu.php/$FAS_IP"
uci add_list dhcp.@dnsmasq[0].address="/$FAS_IP/$FAS_IP"
uci add_list dhcp.@dnsmasq[0].address="/fas.service/$FAS_IP"

# Add upstream DNS server for FAS
uci add_list dhcp.@dnsmasq[0].server="/clients.your-server.de/8.8.8.8"
uci add_list dhcp.@dnsmasq[0].server="/static.97.249.47.78.clients.your-server.de/$FAS_IP"

# Firewall Rules - Allow DNS and HTTP
uci add firewall rule
uci set firewall.@rule[-1].name='Allow-FAS-HTTP'
uci set firewall.@rule[-1].src='lan'
uci set firewall.@rule[-1].proto='tcp'
uci set firewall.@rule[-1].dest_ip="$FAS_IP"
uci set firewall.@rule[-1].dest_port="$FAS_PORT"
uci set firewall.@rule[-1].target='ACCEPT'

# Allow DNS resolution
uci add firewall rule
uci set firewall.@rule[-1].name='Allow-DNS'
uci set firewall.@rule[-1].src='lan'
uci  set firewall.@rule[-1].proto='tcp udp'
uci set firewall.@rule[-1].dest_port='53'
uci set firewall.@rule[-1].target='ACCEPT'


# Network Route
uci add network route
uci set network.@route[-1].target="$FAS_IP"
uci set network.@route[-1].gateway="$ROUTER_IP"
uci set network.@route[-1].interface='lan'

# Add masquerading for FAS
uci add firewall rule
uci set firewall.@rule[-1].name='Masquerade-FAS'
uci set firewall.@rule[-1].src='lan'
uci set firewall.@rule[-1].dest='*'
uci set firewall.@rule[-1].masq='1'

# Add NAT rule for FAS
uci add firewall redirect
uci set firewall.@redirect[-1].name='NAT-FAS-HTTP'
uci set firewall.@redirect[-1].src='lan'
uci set firewall.@redirect[-1].proto='tcp'
uci set firewall.@redirect[-1].src_dport='80'
uci set firewall.@redirect[-1].dest_ip="$FAS_IP"
uci set firewall.@redirect[-1].dest_port="$FAS_PORT"
uci set firewall.@redirect[-1].target='DNAT'

# Add static route
uci add network route
uci set network.@route[-1].target="$FAS_IP"
uci set network.@route[-1].gateway="$ROUTER_IP"
uci set network.@route[-1].interface='wan'


# Apply all changes
uci commit opennds
uci commit firewall
uci commit network
uci commit dhcp

# Add both names to hosts file
echo "$FAS_IP static.97.249.47.78.clients.your-server.de fas.service" >> /etc/hosts

# Restart all services with a reboot
echo "Configuration completed. Rebooting system..."
reboot
