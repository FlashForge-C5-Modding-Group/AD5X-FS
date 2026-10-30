#!/bin/bash
# Build Kalico's c_helper.so for the AD5X, exactly as klippy/chelper would, from kalico-ad5x main
set -ex
W=$HOME/pybuild
CROSS=$HOME/toolchain/mips-xburst2-linux-toolchain-r6.0.0/bin/mips-xburst2-linux-gnu-
OUT=$W/chelper
rm -rf "$W/kalico" "$OUT" && mkdir -p "$OUT"
git clone --depth 1 --branch main https://github.com/FlashForge-C5-Modding-Group/kalico-ad5x.git "$W/kalico"
COMMIT=$(git -C "$W/kalico" rev-parse HEAD)
cd "$W/kalico/klippy/chelper"

# the source list and compile arguments from chelper/__init__.py
SRC=$(python3 - <<'PY'
import re
s = open('__init__.py').read()
m = re.search(r'^SOURCE_FILES = \[(.*?)^\]', s, re.S | re.M)
print(' '.join(re.findall(r'"([^"]+\.c)"', m.group(1))))
PY
)
echo "sources: $SRC"
${CROSS}gcc -Wall -g -O2 -shared -fPIC -flto -fwhole-program -fno-use-linker-plugin -o "$OUT/c_helper.so" $SRC
${CROSS}strip --strip-unneeded "$OUT/c_helper.so"

# fingerprint of every C source and header in the folder, in name order
ls *.c *.h | sort | xargs cat | sha256sum | cut -d' ' -f1 > "$OUT/SOURCES.sha256"
echo "$COMMIT" > "$OUT/KALICO_COMMIT"

ls -l "$OUT"
cat "$OUT/SOURCES.sha256" "$OUT/KALICO_COMMIT"
${CROSS}readelf -h "$OUT/c_helper.so" | grep Flags
${CROSS}readelf -A "$OUT/c_helper.so" | grep "FP ABI"
echo "needs:"; ${CROSS}readelf -d "$OUT/c_helper.so" | grep NEEDED
echo "undefined (resolved by python at load):"; ${CROSS}nm -D --undefined-only "$OUT/c_helper.so" | awk '{print $2}' | tr '\n' ' ' | cut -c1-300; echo
echo "=== CHELPER DONE"
