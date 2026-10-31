#!/bin/sh
# Moonraker (Arksine) on python-hf, data folder = the Klipper folder
MOONRAKER=/usr/data/openad5x/moonraker/moonraker
MPY=/usr/data/openad5x/moonraker/moonraker-env/bin/python
OC=/usr/data/openad5x/klipper
export PATH=$PATH:/opt/bin
# pip (Moonraker's update manager) builds zeroconf as plain Python, finds
# python-hf's zlib/libjpeg for Pillow through CFLAGS/LDFLAGS, and keeps its own cache
export SKIP_CYTHON=1 CFLAGS="-I/usr/data/python-hf/include" LDFLAGS="-L/usr/data/python-hf/lib"
export PIP_CACHE_DIR=/usr/data/openad5x/home/.cache/pip-hf
if [ -z "${HOME:-}" ] || [ "$HOME" = / ]; then
    export HOME=/usr/data/openad5x/home
    mkdir -p "$HOME"
fi

[ -x "$MPY" ] && [ -f "$MOONRAKER/moonraker/moonraker.py" ] || { echo "not installed"; exit 0; }

mkdir -p "$OC/tmp"
rm -rf "$OC/tmp"/*
TMPDIR="$OC/tmp" "$MPY" "$MOONRAKER/moonraker/moonraker.py" -d "$OC" \
	> /usr/data/logs/moonraker.out 2>&1 &
echo "started"
