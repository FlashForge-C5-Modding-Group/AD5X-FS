#!/bin/sh
# nginx from Entware: Fluidd on port 80, the API passed to Moonraker
#
# Copyright (C) 2026  sterling motuz <Sterling@dexabyte.ca>
#
# Made for the OpenAD5X project
#
# This file may be distributed under the terms of the MIT license.
LAUNCHER_LOG="/tmp/openad5x.log"
NGINX=/opt/sbin/nginx
CONF=/usr/data/openad5x/nginx/nginx.conf

log_launcher() {
    echo "$1" >> "$LAUNCHER_LOG"
}

# 05-entfix.sh mounts /opt in parallel with this script
i=0
while [ ! -x "$NGINX" ] && [ $i -lt 60 ]; do
    sleep 1
    i=$((i + 1))
done
[ -x "$NGINX" ] || { log_launcher "nginx is not installed"; exit 0; }

mkdir -p /usr/data/tmp /usr/data/logs
log_launcher "Launching WebUI..."
$NGINX -c $CONF
