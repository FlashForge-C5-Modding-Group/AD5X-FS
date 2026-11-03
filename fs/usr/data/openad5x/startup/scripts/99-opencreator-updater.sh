#!/bin/sh
# Updater: merges AD5X-FS config updates into the live config and keeps the
# openad5x folders current, watching the AD5X-FS checkout Moonraker's update
# manager pulls. The work is in ../opencreator_updater.py.
# Logs to /tmp/openad5x-updater.log.
LOG=/tmp/openad5x-updater.log
HERE=$(cd "$(dirname "$0")/.." && pwd)
export PATH=$PATH:/opt/bin
# FlashForge's startup passes on its LD_LIBRARY_PATH, whose old libraries
# break Entware's git and curl; nothing here needs it.
unset LD_LIBRARY_PATH

for py in /usr/data/python-hf/bin/python3 /usr/data/openad5x/klipper/klippy-env/bin/python /opt/bin/python3; do
    if [ -x "$py" ]; then
        exec "$py" "$HERE/opencreator_updater.py" soc
    fi
done
echo "$(date '+%Y-%m-%d %H:%M:%S') no Python found; updater not running" >>"$LOG"
