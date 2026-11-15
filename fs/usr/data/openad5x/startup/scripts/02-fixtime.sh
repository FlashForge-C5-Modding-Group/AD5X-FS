#!/bin/sh
# Copyright (c) 2026 FlashForge Creator 5 Modding Group
# From https://github.com/FlashForge-C5-Modding-Group/opencreator-fs (commit f6fdd22)
# Edited by sterling motuz <Sterling@dexabyte.ca> for the OpenAD5X project
#
# This file may be distributed under the terms of the MIT license.
(
    n=0
    while [ $n -lt 30 ]; do
        if ping -c1 -W2 time.nist.gov >/dev/null 2>&1; then
            rdate -s time.nist.gov
            break
        fi
        n=$((n+1))
        sleep 2
    done
)