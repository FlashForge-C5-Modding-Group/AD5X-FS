#!/bin/bash
# Cross-build the Kalico host packages for the AD5X Python (small ones first)
set -ex
W=$HOME/pybuild
T=$W/out/root/usr/data/openad5x/python
DEPS=$W/deps
TC=$HOME/toolchain/mips-xburst2-linux-toolchain-r6.0.0
CROSS=$TC/bin/mips-xburst2-linux-gnu-
SD=_sysconfigdata__linux_mipsel-linux-gnu
PIPWHL=$(ls "$T"/lib/python3.14/ensurepip/_bundled/pip-*.whl)
HOSTPY=$W/hostpy
XSYS=$W/xsys
WHEELS=$W/wheels
SP=$T/lib/python3.14/site-packages
mkdir -p "$HOSTPY" "$XSYS" "$WHEELS"
cp "$T/lib/python3.14/$SD.py" "$XSYS/"

echo "=== build-side tools (setuptools, wheel) into $HOSTPY"
PYTHONPATH=$PIPWHL python3 -m pip install --disable-pip-version-check --target "$HOSTPY" setuptools wheel

# crossenv-style: the PC's Python builds extensions with the target's compiler settings
export _PYTHON_SYSCONFIGDATA_NAME=$SD
export _PYTHON_HOST_PLATFORM=linux-mipsel
export CC=${CROSS}gcc CXX=${CROSS}g++ AR=${CROSS}ar
export CFLAGS="-O2 -fPIC -I$T/include/python3.14 -I$DEPS/include"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-L$DEPS/lib -static-libgcc -static-libstdc++"
export PYTHONPATH=$PIPWHL:$HOSTPY:$XSYS

echo "=== wheels"
python3 -m pip wheel --disable-pip-version-check --no-build-isolation --no-deps -w "$WHEELS" \
    pyserial==3.4 jinja2==3.1.6 markupsafe==3.0.3 pycparser==2.22 cffi==2.0.0 greenlet==3.3.0
ls -l "$WHEELS"

echo "=== install into the target site-packages"
for w in "$WHEELS"/*.whl; do unzip -oq "$w" -d "$SP"; done
ls "$SP"

echo "=== architecture of every compiled module"
find "$SP" -name '*.so' | while read -r f; do
    printf '%s  ' "${f#$SP/}"
    ${CROSS}readelf -h "$f" | grep -E "Flags" | awk '{print $2, $3, $4, $5}'
done
echo "=== PKGS DONE"
