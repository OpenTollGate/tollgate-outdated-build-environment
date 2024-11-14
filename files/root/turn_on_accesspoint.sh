#!/bin/sh /etc/rc.common

uci set wireless.default_radio0.disabled=0
uci commit wireless
wifi  up

