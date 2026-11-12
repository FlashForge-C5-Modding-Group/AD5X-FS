#!/bin/sh
GRUMPY=/usr/data/grumpyscreen/grumpyscreen
[ -x "$GRUMPY" ] || exit 0

# This GrumpyScreen has no touch calibration: it uses the driver's numbers as screen pixels. The driver
# is loaded again, once per boot, with 0..800 x 0..480 mapped onto the panel's real touch window.
TSC_PARAMS="tsc_irq_gpio=PC07 tsc_power_on_gpio=-1 tsc_regulator_name=-1 tsc_i2c_bus=0 tsc_i2c_addr=0x48 tsc_x_plate_ohms=660 tsc_max_rt=600 tsc_fuzzx=0 tsc_fuzzy=0 tsc_fuzzz=0 tsc_poll_period=0 tsc_xy_coords_exchange=0 tsc_x_coords_flip=0 tsc_y_coords_flip=1"
if [ ! -f /tmp/openad5x-touch ] && [ -f /module_driver/tsc2007_touch.ko ]; then
    rmmod tsc2007_touch 2>/dev/null
    insmod /module_driver/tsc2007_touch.ko $TSC_PARAMS tsc_x_coords_max=800 tsc_y_coords_max=480 tsc_x_actrue_min=309 tsc_x_actrue_max=3765 tsc_y_actrue_min=705 tsc_y_actrue_max=3447 ||
        insmod /module_driver/tsc2007_touch.ko $TSC_PARAMS tsc_x_coords_max=800 tsc_y_coords_max=480 tsc_x_actrue_min=0 tsc_x_actrue_max=4096 tsc_y_actrue_min=0 tsc_y_actrue_max=4096
    touch /tmp/openad5x-touch
    sleep 1
fi

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
        # AFC in the config: MMU panel on, unless another backend was chosen
        if grep -q '^\[include AFC/' "$CONFIG_DIR/printer.cfg" 2>/dev/null && grep -q '^backend: none' "$CONFIG"; then
            sed -i '/^\[mmu\]/,/^\[/ s/^backend: none/backend: afc/' "$CONFIG"
        fi
    fi
fi

(
    while true; do
        "$GRUMPY" >> /usr/data/logs/grumpyscreen.log 2>&1
        sleep 3
    done
) &
echo "started"
