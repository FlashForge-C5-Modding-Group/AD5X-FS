#!/bin/sh
# Moonraker (Arksine) on the AD5X Python, data folder = the Klipper folder
PYDIR=/usr/data/openad5x/python
MR_DIR=/usr/data/openad5x/moonraker
OC=/usr/data/openad5x/klipper

[ -f $MR_DIR/moonraker/moonraker.py ] || { echo "not installed"; exit 0; }

# libnacl loads libsodium from the Python's lib folder
LD_LIBRARY_PATH=$PYDIR/lib \
SSL_CERT_FILE=$PYDIR/lib/python3.14/site-packages/certifi/cacert.pem \
$PYDIR/bin/python3.14 $MR_DIR/moonraker/moonraker.py -d $OC \
	> /usr/data/logs/moonraker.out 2>&1 &
echo "started"
