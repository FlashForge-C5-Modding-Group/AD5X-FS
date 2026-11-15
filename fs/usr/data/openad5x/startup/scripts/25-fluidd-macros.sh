#!/bin/sh
# Copyright (c) 2026 FlashForge Creator 5 Modding Group
# From https://github.com/FlashForge-C5-Modding-Group/opencreator-fs (commit f6fdd22)
# Edited by sterling motuz <Sterling@dexabyte.ca> for the OpenAD5X project
#
# This file may be distributed under the terms of the MIT license.
API=http://127.0.0.1:7125/server/database/item
MACROS=/usr/data/openad5x/fluidd/macros.json
export PATH=$PATH:/opt/bin
# FlashForge's startup passes on its LD_LIBRARY_PATH, whose old libcurl
# breaks curl (undefined symbol curl_mime_free); nothing here needs it.
unset LD_LIBRARY_PATH
[ -f "$MACROS" ] || exit 0

i=0
until curl -fs http://127.0.0.1:7125/server/info >/dev/null 2>&1; do
    i=$((i + 1))
    [ $i -ge 120 ] && exit 0
    sleep 5
done

curl -fs "$API?namespace=fluidd&key=macros" >/dev/null 2>&1 && exit 0
{ printf '{"namespace":"fluidd","key":"macros","value":'; cat "$MACROS"; printf '}'; } |
    curl -fs -X POST -H 'Content-Type: application/json' -d @- "$API" >/dev/null
