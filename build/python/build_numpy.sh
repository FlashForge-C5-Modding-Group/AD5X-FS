#!/bin/bash
# Cross-build numpy for the AD5X Python
set -ex
W=$HOME/pybuild
TP=/usr/data/openad5x/python
T=$W/out/root$TP
DEPS=$W/deps
TC=$HOME/toolchain/mips-xburst2-linux-toolchain-r6.0.0
CROSS=$TC/bin/mips-xburst2-linux-gnu-
SD=_sysconfigdata__linux_mipsel-linux-gnu
PIPWHL=$(ls "$T"/lib/python3.14/ensurepip/_bundled/pip-*.whl)
HOSTPY=$W/hostpy
XSYS=$W/xsys
WHEELS=$W/wheels
SP=$T/lib/python3.14/site-packages
mkdir -p "$HOSTPY" "$XSYS" "$WHEELS" "$W/tmp"

echo "=== build-side tools for numpy (meson-python, meson, ninja, cython)"
PYTHONPATH=$PIPWHL python3 -m pip install --disable-pip-version-check --target "$HOSTPY" meson-python meson ninja cython setuptools wheel

# pip --target leaves the ninja binary inside the wheel's scripts folder; put it where meson-python looks
mkdir -p "$HOSTPY/bin" "$W/ninja-wheel"
PYTHONPATH=$PIPWHL python3 -m pip download --disable-pip-version-check --no-deps ninja -d "$W/ninja-wheel"
unzip -oj "$W"/ninja-wheel/ninja-*.whl 'ninja-*.data/scripts/ninja' -d "$HOSTPY/bin"
chmod +x "$HOSTPY/bin/ninja"
"$HOSTPY/bin/ninja" --version

# same gap for cython's command: call its own entry point
cat > "$HOSTPY/bin/cython" <<'EOF'
#!/bin/bash
exec python3 -c 'import sys; from Cython.Compiler.Main import setuptools_main; sys.exit(setuptools_main())' "$@"
EOF
chmod +x "$HOSTPY/bin/cython"
PYTHONPATH=$HOSTPY "$HOSTPY/bin/cython" --version

# the target's build settings, with its install prefix pointed at the staged copy so paths exist on the PC
sed "s#$TP#$T#g" "$T/lib/python3.14/$SD.py" > "$XSYS/$SD.py"

cat > "$W/cross.txt" <<EOF
[binaries]
c = '${CROSS}gcc'
cpp = '${CROSS}g++'
ar = '${CROSS}ar'
strip = '${CROSS}strip'

[host_machine]
system = 'linux'
cpu_family = 'mips'
cpu = 'mips32r2'
endian = 'little'

[properties]
needs_exe_wrapper = true
longdouble_format = 'IEEE_DOUBLE_LE'

[built-in options]
c_args = ['-O2', '-fPIC', '-I$DEPS/include']
cpp_args = ['-O2', '-fPIC', '-I$DEPS/include']
c_link_args = ['-static-libgcc', '-L$DEPS/lib']
cpp_link_args = ['-static-libgcc', '-static-libstdc++', '-L$DEPS/lib']
EOF
cat "$W/cross.txt"

export _PYTHON_SYSCONFIGDATA_NAME=$SD
export _PYTHON_HOST_PLATFORM=linux-mipsel
export CC=${CROSS}gcc CXX=${CROSS}g++ AR=${CROSS}ar
export PYTHONPATH=$PIPWHL:$HOSTPY:$XSYS
export PATH=$HOSTPY/bin:$PATH
export TMPDIR=$W/tmp

echo "=== numpy wheel"
python3 -m pip wheel --disable-pip-version-check --no-build-isolation --no-deps -w "$WHEELS" numpy==2.3.5 \
    -Csetup-args=--cross-file="$W/cross.txt" \
    -Csetup-args=-Dallow-noblas=true \
    -Csetup-args=-Dblas=none -Csetup-args=-Dlapack=none \
    -Csetup-args=-Dcpu-baseline=none -Csetup-args=-Dcpu-dispatch=none \
    -Csetup-args=-Ddisable-svml=true -Csetup-args=-Ddisable-highway=true \
    -Cbuild-dir="$W/numpy-build" -Ccompile-args=-j24
ls -l "$WHEELS"/numpy*

echo "=== install into target"
unzip -oq "$WHEELS"/numpy-2.3.5-*.whl -d "$SP"
echo "=== architecture of numpy's compiled modules"
find "$SP/numpy" -name '*.so' | head -40 | while read -r f; do
    printf '%s  ' "${f#$SP/}"
    ${CROSS}readelf -h "$f" | grep Flags | awk '{print $2, $4, $5}'
done
du -sh "$SP/numpy"
echo "=== NUMPY DONE"
