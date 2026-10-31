#!/bin/sh
# Restart Wi-Fi after GrumpyScreen joins a network (its restart_wifi_cmd)
killall wpa_supplicant udhcpc 2>/dev/null
sleep 1
ifconfig wlan0 up
wpa_supplicant -Dnl80211 -iwlan0 -c/usr/prog/wifi/wpa_supplicant.conf -B
udhcpc -b -i wlan0 -p /var/run/udhcpc.pid
