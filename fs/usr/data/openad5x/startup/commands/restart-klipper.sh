#!/bin/sh
# stop every klippy.py; the loop in startup/scripts/10-klipper.sh starts Kalico again
#
# Copyright (C) 2026  sterling motuz <Sterling@dexabyte.ca>
#
# Made for the OpenAD5X project
#
# This file may be distributed under the terms of the MIT license.
pids() {
    for p in /proc/[0-9]*; do
        { tr '\0' ' ' < $p/cmdline; } 2>/dev/null | grep -q "$1" && echo ${p#/proc/}
    done
}
kill $(pids 'klippy\.py') 2>/dev/null
i=0
while [ -n "$(pids 'klippy\.py')" ] && [ $i -lt 5 ]; do sleep 1; i=$((i + 1)); done
kill -9 $(pids 'klippy\.py') 2>/dev/null
sleep 5
pids 'klippy\.py' | wc -l
