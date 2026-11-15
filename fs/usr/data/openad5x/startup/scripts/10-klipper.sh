#!/bin/sh
# Copyright (c) 2026 FlashForge Creator 5 Modding Group
# From https://github.com/FlashForge-C5-Modding-Group/opencreator-fs (commit f6fdd22)
# Edited by sterling motuz <Sterling@dexabyte.ca> for the OpenAD5X project
#
# This file may be distributed under the terms of the MIT license.
LAUNCHER_LOG="/tmp/openad5x.log"
OC=/usr/data/openad5x/klipper
KPY=$OC/klippy-env/bin/python
export PATH=$PATH:/opt/bin

log_launcher() {
    echo "$1" >> "$LAUNCHER_LOG"
}

# AFC stops with an error while its variables file is missing or empty; it
# fills the file in itself once it has state to save.
for AFC_VARS in "$OC/config/AFC/AFC.var.unit" "$OC/config/AFC/AFC.var"; do
    if [ ! -s "$AFC_VARS" ]; then
        mkdir -p "$OC/config/AFC"
        echo '{}' > "$AFC_VARS"
    fi
done

# 08-mcu-wake.sh starts (and flashes) the eboard first
i=0
while [ ! -e /tmp/openad5x-eboard-ready ] && [ $i -lt 90 ]; do
    sleep 1
    i=$((i + 1))
done

PLUGINS=/usr/data/openad5x/plugin-manager/oc-plugin
[ -d /opt/bin ] && [ -f "$PLUGINS" ] && ln -sf "$PLUGINS" /opt/bin/oc-plugin

while true; do
    if [ -x "$KPY" ]; then
        # Plugin modules and configs, redone before every start (Fluidd updates plugins with git pull)
        [ -f "$PLUGINS" ] && sh "$PLUGINS" sync --only klipper >> "$LAUNCHER_LOG" 2>&1
        log_launcher "Klippy is starting..."

        "$KPY" "$OC/klipper/klippy/klippy.py" "$OC/config/printer.cfg" -l "$OC/logs/printer.log" -a /tmp/uds

        log_launcher "Klippy exited; see $OC/logs/printer.log. Restarting in 3 s."
        log_launcher "ERR CODE 0 - Klippy"
    fi
    sleep 3
done
