#!/bin/sh
GRUMPY=/usr/data/grumpyscreen/grumpyscreen
[ -x "$GRUMPY" ] || exit 0

TOUCH=$(awk '
    /^N: Name=/ { name = tolower($0) }
    /^H: Handlers=/ && name ~ /goodix|touch/ {
        for (i = 2; i <= NF; i++)
            if ($i ~ /^event[0-9]+$/) { print "/dev/input/" $i; exit }
    }' /proc/bus/input/devices 2>/dev/null)
export LVGL_EVDEV_DEV=${TOUCH:-/dev/input/event1}

# right way up on the AD5X (rotation 0)
export DISPLAY_ROTATE=0

# The config folder's copy wins, so it can be edited from Fluidd or Mainsail.
CONFIG_DIR=/usr/data/openad5x/klipper/config
CONFIG=$CONFIG_DIR/grumpyscreen.cfg
if [ -d "$CONFIG_DIR" ]; then
    [ -f "$CONFIG" ] || cp "${GRUMPY}.cfg" "$CONFIG" 2>/dev/null
    if [ -f "$CONFIG" ]; then
        export CONFIG_FILE="$CONFIG"
        # AFC installed: MMU panel on, unless another backend was chosen
        if [ -d /usr/data/AFC-Klipper-Add-On ] && grep -q '^backend: none' "$CONFIG"; then
            sed -i '/^\[mmu\]/,/^\[/ s/^backend: none/backend: afc/' "$CONFIG"
        fi
        # the Wi-Fi panel restarts Wi-Fi with this after joining a network
        sed -i 's|^restart_wifi_cmd:.*|restart_wifi_cmd: /bin/sh /usr/data/openad5x/restart_wifi.sh|' "$CONFIG"
    fi
fi

(
    while true; do
        "$GRUMPY" >> /usr/data/logs/grumpyscreen.log 2>&1
        sleep 3
    done
) &
echo "started"
