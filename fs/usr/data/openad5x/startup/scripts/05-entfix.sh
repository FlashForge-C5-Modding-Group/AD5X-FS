#!/bin/sh
# Copyright (c) 2026 FlashForge Creator 5 Modding Group
# From https://github.com/FlashForge-C5-Modding-Group/opencreator-fs (commit f6fdd22)
# Edited by sterling motuz <Sterling@dexabyte.ca> for the OpenAD5X project
#
# This file may be distributed under the terms of the MIT license.
[ -x /opt/bin/opkg ] || [ -d /usr/data/bin/opt ] || exit 0
sh /usr/data/openad5x/startup/scripts/01-fixnan.sh || exit 1
[ -x /opt/bin/opkg ] || grep -q ' /opt ' /proc/mounts || mount --bind /usr/data/bin/opt /opt
[ -x /opt/etc/init.d/rc.unslung ] && /opt/etc/init.d/rc.unslung start
