#!/bin/sh
# Restart Wi-Fi after GrumpyScreen joins a network (its restart_wifi_cmd)
#
# Copyright (C) 2026  sterling motuz <Sterling@dexabyte.ca>
#
# Made for the OpenAD5X project
#
# This file may be distributed under the terms of the MIT license.
CFG=/usr/prog/config/Adventurer5M.json
net_get() {
	sed -n '/"network"/,/}/s/.*"'"$1"'" *: *"\{0,1\}\([^",]*\).*/\1/p' "$CFG" | head -n 1
}

# only Wi-Fi's DHCP client, eth0 keeps its own
for pid in $(pidof udhcpc); do
	tr '\0' ' ' < /proc/$pid/cmdline | grep -q wlan0 && kill $pid
done
killall wpa_supplicant 2>/dev/null
sleep 1
ifconfig wlan0 up
wpa_supplicant -Dnl80211 -iwlan0 -c/usr/prog/wifi/wpa_supplicant.conf -B
if [ "$(net_get isManual)" = true ]; then
	ifconfig wlan0 "$(net_get configIp)" netmask "$(net_get configNetmask)"
	gw=$(net_get configGateway)
	[ -n "$gw" ] && route add default gw "$gw"
	dns=$(net_get configDns)
	[ -n "$dns" ] && echo "nameserver $dns # wlan0" > /etc/resolv.conf
else
	udhcpc -b -i wlan0 -p /var/run/udhcpc-wlan0.pid
fi
