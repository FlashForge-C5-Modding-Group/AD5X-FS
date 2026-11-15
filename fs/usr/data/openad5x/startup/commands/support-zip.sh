#!/bin/sh
# GrumpyScreen "support zip" button: logs, configs (secrets removed) and system details in config/support.zip
#
# Copyright (C) 2026  sterling motuz <Sterling@dexabyte.ca>
#
# Made for the OpenAD5X project
#
# This file may be distributed under the terms of the MIT license.

CFG=/usr/data/openad5x/klipper/config
OUT=/tmp/openad5x-support
rm -rf "$OUT"
mkdir -p "$OUT/logs" "$OUT/config"

# last 2 MB of every log: Klipper, AFC, Moonraker, screen, boot
for f in /usr/data/openad5x/klipper/logs/*.log /usr/data/logs/*.log /tmp/*.log; do
    [ -f "$f" ] && tail -c 2000000 "$f" > "$OUT/logs/${f##*/}"
done

# configs with passwords, tokens, keys and URLs blanked
cd "$CFG" || exit 1
find . -name '*.cfg' -o -name '*.conf' | while read -r f; do
    mkdir -p "$OUT/config/${f%/*}"
    sed -E 's/^([[:space:]]*[A-Za-z_]*(password|token|secret|key|url)[A-Za-z_]*[[:space:]]*[:=]).*/\1 <removed>/I' "$f" > "$OUT/config/$f"
done

{
    date; uname -a
    cat /usr/data/openad5x/version.txt /usr/data/openad5x/install.json
    /opt/bin/git -C /usr/data/openad5x/klipper/klipper log -1 --oneline
    /opt/bin/git -C /usr/data/openad5x/ad5x-fs log -1 --oneline
    df -h /usr/data /usr/prog /tmp; free; ps w
} > "$OUT/system.txt" 2>&1

rm -f "$CFG/support.zip"
cd "$OUT" && /usr/data/python-hf/bin/python3 -m zipfile -c "$CFG/support.zip" logs config system.txt
rm -rf "$OUT"
