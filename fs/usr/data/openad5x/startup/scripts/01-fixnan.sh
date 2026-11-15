#!/bin/sh
# Copyright (c) 2026 FlashForge Creator 5 Modding Group
# From https://github.com/FlashForge-C5-Modding-Group/opencreator-fs (commit f6fdd22)
# Edited by sterling motuz <Sterling@dexabyte.ca> for the OpenAD5X project
#
# This file may be distributed under the terms of the MIT license.
case "$(ls /usr/prog/PROGRAM/kernel/ 2>/dev/null | head -n 1)" in
    2.0.1)
        busybox devmem 0x00a130d1 8 1
        ;;
    *)
        echo "Unknown kernel package; legacy NaN not enabled" >&2
        exit 1
        ;;
esac
