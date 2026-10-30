#!/bin/sh
# Moonraker (Arksine) in /usr/prog/moonraker on the hard-float Python, data folder = the Klipper folder
LAUNCHER_LOG="/tmp/openad5x.log"
OC=/usr/data/openad5x/klipper
MOONRAKER=/usr/prog/moonraker/moonraker
MPY=/usr/prog/moonraker/moonraker-env/bin/python
export PATH=$PATH:/opt/bin

# HOME is the read-only / at boot
if [ -z "${HOME:-}" ] || [ "$HOME" = / ]; then
    export HOME=/usr/data/openad5x/home
    mkdir -p "$HOME"
fi

log_launcher() {
    echo "$1" >> "$LAUNCHER_LOG"
}

mkdir -p "$OC/tmp"

while true; do
    if [ -x "$MPY" ]; then
        log_launcher "Launching Moonraker..."
        rm -rf "$OC/tmp"/*
        TMPDIR="$OC/tmp" "$MPY" "$MOONRAKER/moonraker/moonraker.py" -d "$OC"
        log_launcher "Moonraker exited; restarting in 3 s."
    fi
    sleep 3
done
