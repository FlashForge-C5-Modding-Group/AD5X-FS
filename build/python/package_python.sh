#!/bin/bash
# Trim a copy of the AD5X Python and package it
set -ex
W=$HOME/pybuild
SRCROOT=$W/out/root/usr/data/openad5x/python
CROSS=$HOME/toolchain/mips-xburst2-linux-toolchain-r6.0.0/bin/mips-xburst2-linux-gnu-
P=$W/pkg
DEST=${OUT_DIR:-$HOME/pybuild/dist}
NAME=ad5x-python-3.14.4-mipsel.tar.gz

rm -rf "$P" && mkdir -p "$P"
cp -a "$SRCROOT" "$P/python"
cd "$P/python"
echo "before: $(du -sh . | cut -f1)"

L=lib/python3.14
rm -rf $L/test $L/idlelib $L/turtledemo $L/tkinter $L/config-* include share lib/pkgconfig
rm -f lib/libpython*.a bin/idle* bin/pydoc* bin/python3*-config
rm -f $L/lib-dynload/_test*.so $L/lib-dynload/_xx*.so $L/lib-dynload/xxlimited*.so $L/lib-dynload/_ctypes_test*.so
find . -type d \( -name tests -o -name test -o -name testing \) -not -path "./$L/site-packages/pip/*" -prune -exec rm -rf {} +
find . -name '*.pyc' -path '*tests*' -delete 2>/dev/null || true

# one record per package: an older markupsafe was overlaid by the newer one a dependency pulled in
rm -rf "$L"/site-packages/markupsafe-3.0.3.dist-info

# debug symbols
find . -type f \( -name '*.so' -o -name '*.so.*' \) -exec ${CROSS}strip --strip-unneeded {} +
${CROSS}strip --strip-unneeded bin/python3.14
echo "after:  $(du -sh . | cut -f1)"

# Kalico's C helper, built from kalico-ad5x main (the installer checks SOURCES.sha256 against the checkout)
mkdir -p chelper
cp "$W"/chelper/c_helper.so "$W"/chelper/SOURCES.sha256 "$W"/chelper/KALICO_COMMIT chelper/

cat > BUILDINFO <<EOF
Python 3.14.4 for the FlashForge AD5X (MIPS32r2, NaN2008, hard-float FP64, glibc 2.33)
Built $(date -u +%Y-%m-%d) with the Ingenic xburst2 GCC 12.1 toolchain, from python.org source
Install prefix: /usr/data/openad5x/python
Statically linked: zlib 1.3.1, libffi 3.4.6, OpenSSL 3.0.16, bzip2 1.0.8, xz 5.4.6, sqlite 3.54.1
Packages: numpy 2.3.5, cffi 2.0.0, greenlet 3.3.0, markupsafe 3.0.4, jinja2 3.1.6, pyserial 3.4, pycparser 2.22, pip 26.0.1, and the ones Moonraker needs (pillow, tornado, streaming-form-data, apprise, zeroconf, dbus-fast, ...)
sqlite 3.54.1 is built into _sqlite3; libsodium 1.0.20 is lib/libsodium.so.26 (set LD_LIBRARY_PATH to this lib folder for libnacl)
moonraker/ (next to python/): Arksine Moonraker b559b9a81161f958a43c2f527b6ad96f73310d5d
Needs on the printer: libc, libm, libdl, libpthread, libutil, libatomic.so.1 (all stock)
chelper/: c_helper.so for kalico-ad5x $(cat "$W/chelper/KALICO_COMMIT"), valid only while the checkout's C sources hash to chelper/SOURCES.sha256
EOF

# Moonraker (Arksine), the commit its requirements were taken from
cd "$P"
curl -fL -o moonraker.tar.gz https://codeload.github.com/Arksine/moonraker/tar.gz/b559b9a81161f958a43c2f527b6ad96f73310d5d
mkdir moonraker && tar -xzf moonraker.tar.gz -C moonraker --strip-components=1
rm -f moonraker.tar.gz
rm -rf moonraker/.github moonraker/docs moonraker/.git moonraker/tests moonraker/.gitignore
echo "b559b9a81161f958a43c2f527b6ad96f73310d5d" > moonraker/COMMIT
echo "moonraker: $(du -sh moonraker | cut -f1), $(find moonraker -type f | wc -l) files"
cd "$P/python"

mkdir -p "$DEST"
tar -C "$P" -cf - python moonraker | gzip -9 > "$DEST/$NAME"
(cd "$DEST" && sha256sum "$NAME" > "$NAME.sha256")
ls -l "$DEST"
cat "$DEST/$NAME.sha256"
echo "files in package: $(tar -tzf "$DEST/$NAME" | wc -l)"
echo "top level: $(tar -tzf "$DEST/$NAME" | cut -d/ -f1-2 | sort -u | head -8 | tr '\n' ' ')"
echo "=== PACKAGED"
