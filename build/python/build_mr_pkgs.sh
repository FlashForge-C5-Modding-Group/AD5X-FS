#!/bin/bash
# Cross-build / download Moonraker's Python packages for the AD5X Python
set -ex
MRC=${1:?moonraker commit}
W=$HOME/pybuild
TP=/usr/data/openad5x/python
T=$W/out/root$TP
DEPS=$W/deps
CROSS=$HOME/toolchain/mips-xburst2-linux-toolchain-r6.0.0/bin/mips-xburst2-linux-gnu-
SD=_sysconfigdata__linux_mipsel-linux-gnu
PIPWHL=$(ls "$T"/lib/python3.14/ensurepip/_bundled/pip-*.whl)
HOSTPY=$W/hostpy
XSYS=$W/xsys
WHEELS=$W/wheels
SP=$T/lib/python3.14/site-packages
mkdir -p "$WHEELS" "$XSYS" "$W/tmp"

# more build-side tools (PC only): pillow needs pybind11
PYTHONPATH=$PIPWHL python3 -m pip install --disable-pip-version-check --target "$HOSTPY" pybind11 "setuptools>=77" poetry-core hatchling flit-core setuptools-scm

# the target's build settings, with the install prefix pointed at the staged copy so the paths exist here
sed "s#$TP#$T#g" "$T/lib/python3.14/$SD.py" > "$XSYS/$SD.py"

curl -fL -o "$W/mr-requirements.txt" "https://raw.githubusercontent.com/Arksine/moonraker/$MRC/scripts/moonraker-requirements.txt"
grep -v '^--find-links' "$W/mr-requirements.txt" | grep -v '^pillow' | grep -v '^\s*$' > "$W/mr-req-rest.txt"
cat "$W/mr-req-rest.txt"

export _PYTHON_SYSCONFIGDATA_NAME=$SD
export _PYTHON_HOST_PLATFORM=linux-mipsel
export CC=${CROSS}gcc CXX=${CROSS}g++ AR=${CROSS}ar
export CFLAGS="-O2 -fPIC -I$T/include/python3.14 -I$DEPS/include"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-L$DEPS/lib -static-libgcc -static-libstdc++"
export PYTHONPATH=$PIPWHL:$HOSTPY:$XSYS
export PATH=$HOSTPY/bin:$PATH
export TMPDIR=$W/tmp
export SKIP_CYTHON=1

echo "=== pillow (zlib only: gcode thumbnails are PNG)"
python3 -m pip wheel --disable-pip-version-check --no-build-isolation --no-deps -w "$WHEELS" "pillow<=12.3.0" \
    -C platform-guessing=disable -C zlib=enable -C jpeg=disable -C tiff=disable -C freetype=disable -C lcms=disable \
    -C webp=disable -C jpeg2000=disable -C imagequant=disable -C xcb=disable -C raqm=disable -C fribidi=disable \
    -C harfbuzz=disable -C avif=disable

echo "=== the rest of Moonraker's requirements (and their dependencies)"
unset SKIP_CYTHON
export SKIP_CYTHON=1
python3 -m pip wheel --disable-pip-version-check --no-build-isolation -w "$WHEELS" --find-links "$WHEELS" -r "$W/mr-req-rest.txt"
ls -l "$WHEELS" | awk '{print $5, $9}'

echo "=== install into the target site-packages"
for w in "$WHEELS"/*.whl; do unzip -oq "$w" -d "$SP"; done
ls "$SP" | grep dist-info | tr '\n' ' '; echo

echo "=== architecture of every compiled module added"
find "$SP" -name '*.so' -newer "$W/xsys/$SD.py" | while read -r f; do
    printf '%s  ' "${f#$SP/}"
    ${CROSS}readelf -h "$f" | grep Flags | awk '{print $2, $4, $5}'
done
echo "=== MR PKGS DONE"
