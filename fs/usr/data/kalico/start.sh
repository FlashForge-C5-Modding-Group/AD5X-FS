#!/bin/sh
# Kalico klippy on python-hf, restarts after exit
export PATH=/usr/data/python-hf/cc/bin:$PATH:/opt/bin
K=/usr/data/kalico
cd /
while true; do
    $K/klippy-env/bin/python $K/klipper/klippy/klippy.py /usr/data/config/kalico/printer.cfg \
        -l /usr/data/logs/klippy.log -a /tmp/uds >> /usr/data/logs/klippy.out 2>&1 < /dev/null
    sleep 3
done
