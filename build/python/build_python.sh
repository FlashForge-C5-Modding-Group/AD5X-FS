#!/bin/bash
# Cross-build Python for the AD5X with the Ingenic toolchain (same ABI as the stock programs)
set -ex
TC=$HOME/toolchain/mips-xburst2-linux-toolchain-r6.0.0
CROSS=$TC/bin/mips-xburst2-linux-gnu-
HOST=mips-xburst2-linux-gnu
W=$HOME/pybuild
SRC=$W/src
DEPS=$W/deps
OUT=$W/out
TARGET_PREFIX=/usr/data/openad5x/python
mkdir -p "$SRC" "$DEPS" "$OUT"
cd "$SRC"

fetch() {  # fetch URL
    f=$(basename "$1")
    [ -f "$f" ] || curl -fL --retry 3 -o "$f" "$1"
}
fetch https://www.python.org/ftp/python/3.14.4/Python-3.14.4.tar.xz
fetch https://zlib.net/fossils/zlib-1.3.1.tar.gz
fetch https://github.com/libffi/libffi/releases/download/v3.4.6/libffi-3.4.6.tar.gz
fetch https://github.com/openssl/openssl/releases/download/openssl-3.0.16/openssl-3.0.16.tar.gz
fetch https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz
fetch https://github.com/tukaani-project/xz/releases/download/v5.4.6/xz-5.4.6.tar.gz
fetch https://www.sqlite.org/2026/sqlite-autoconf-3540100.tar.gz
fetch https://download.libsodium.org/libsodium/releases/libsodium-1.0.20.tar.gz
for t in zlib-1.3.1.tar.gz libffi-3.4.6.tar.gz openssl-3.0.16.tar.gz Python-3.14.4.tar.xz bzip2-1.0.8.tar.gz xz-5.4.6.tar.gz sqlite-autoconf-3540100.tar.gz libsodium-1.0.20.tar.gz; do
    d=${t%.tar.*}
    [ -d "$d" ] || tar -xf "$t"
done

export CC=${CROSS}gcc AR=${CROSS}ar RANLIB=${CROSS}ranlib STRIP=${CROSS}strip READELF=${CROSS}readelf
export CFLAGS="-O2 -fPIC"

echo "=== zlib"
if [ ! -f "$DEPS/lib/libz.a" ]; then
    cd "$SRC/zlib-1.3.1" && ./configure --prefix="$DEPS" --static && make -j"$(nproc)" && make install
fi

echo "=== libffi"
if [ ! -f "$DEPS/lib/libffi.a" ]; then
    mkdir -p "$SRC/libffi-build" && cd "$SRC/libffi-build"
    "$SRC/libffi-3.4.6/configure" --host=$HOST --prefix="$DEPS" --disable-shared --enable-static --with-pic --disable-docs
    make -j"$(nproc)" && make install
fi
# libffi installs into lib or lib32 depending on the target
[ -f "$DEPS/lib/libffi.a" ] || cp "$DEPS"/lib*/libffi.a "$DEPS/lib/"

echo "=== openssl"
if [ ! -f "$DEPS/lib/libssl.a" ] && [ ! -f "$DEPS/lib64/libssl.a" ]; then
    cd "$SRC/openssl-3.0.16"
    # OpenSSL adds the cross prefix itself, so CC must not already carry it
    unset CC AR RANLIB STRIP READELF
    make distclean >/dev/null 2>&1 || true
    ./Configure linux-generic32 --cross-compile-prefix=${CROSS} --prefix="$DEPS" --openssldir=$TARGET_PREFIX/ssl \
        no-shared no-tests no-async -fPIC
    make -j"$(nproc)" build_libs
    make install_dev
    export CC=${CROSS}gcc AR=${CROSS}ar RANLIB=${CROSS}ranlib STRIP=${CROSS}strip READELF=${CROSS}readelf
fi
ls "$DEPS/lib"*/libssl.a "$DEPS/include/openssl/ssl.h"
SSLDIR=$DEPS

echo "=== bzip2"
if [ ! -f "$DEPS/lib/libbz2.a" ]; then
    cd "$SRC/bzip2-1.0.8"
    make clean >/dev/null 2>&1 || true
    make -j"$(nproc)" CC="$CC" AR="$AR" RANLIB="$RANLIB" CFLAGS="-O2 -fPIC -D_FILE_OFFSET_BITS=64" libbz2.a
    cp libbz2.a "$DEPS/lib/"
    cp bzlib.h "$DEPS/include/"
fi

echo "=== xz (liblzma)"
if [ ! -f "$DEPS/lib/liblzma.a" ]; then
    mkdir -p "$SRC/xz-build" && cd "$SRC/xz-build"
    "$SRC/xz-5.4.6/configure" --host=$HOST --prefix="$DEPS" --disable-shared --enable-static --with-pic \
        --disable-xz --disable-xzdec --disable-lzmadec --disable-lzmainfo --disable-scripts --disable-doc --disable-nls
    make -j"$(nproc)"
    make install
fi
ls -l "$DEPS/lib/libbz2.a" "$DEPS/lib/liblzma.a"

echo "=== sqlite (the amalgamation, compiled directly)"
if [ ! -f "$DEPS/lib/libsqlite3.a" ]; then
    cd "$SRC/sqlite-autoconf-3540100"
    ${CROSS}gcc -O2 -fPIC -DSQLITE_ENABLE_FTS5 -DSQLITE_THREADSAFE=1 -c sqlite3.c -o sqlite3.o
    ${CROSS}ar rcs libsqlite3.a sqlite3.o
    mkdir -p "$DEPS/lib" "$DEPS/include"
    cp libsqlite3.a "$DEPS/lib/"
    cp sqlite3.h sqlite3ext.h "$DEPS/include/"
fi

echo "=== libsodium (shared: libnacl loads it at run time)"
if [ ! -f "$DEPS/lib/libsodium.so" ]; then
    mkdir -p "$SRC/sodium-build" && cd "$SRC/sodium-build"
    "$SRC/libsodium-1.0.20/configure" --host=$HOST --prefix="$DEPS" --enable-shared --disable-static
    make -j"$(nproc)"
    make install
fi
ls -l "$DEPS"/lib/libsqlite3.a "$DEPS"/lib/libsodium.so*

echo "=== python"
rm -rf "$W/pybuild-dir"
mkdir -p "$W/pybuild-dir" && cd "$W/pybuild-dir"
BUILD_PY=$(command -v python3)
"$BUILD_PY" --version
if [ ! -f Makefile ]; then
    "$SRC/Python-3.14.4/configure" \
        --host=$HOST --build=x86_64-linux-gnu \
        --prefix=$TARGET_PREFIX \
        --with-build-python="$BUILD_PY" \
        --with-openssl="$SSLDIR" \
        --with-ensurepip=install \
        --disable-ipv6 \
        ac_cv_file__dev_ptmx=yes ac_cv_file__dev_ptc=no \
        CPPFLAGS="-I$DEPS/include" LDFLAGS="-L$DEPS/lib -static-libgcc" LIBS="-latomic" \
        LIBFFI_CFLAGS="-I$DEPS/include" LIBFFI_LIBS="-L$DEPS/lib -lffi" \
        ZLIB_CFLAGS="-I$DEPS/include" ZLIB_LIBS="-L$DEPS/lib -lz" \
        BZIP2_CFLAGS="-I$DEPS/include" BZIP2_LIBS="-L$DEPS/lib -lbz2" \
        LIBLZMA_CFLAGS="-I$DEPS/include" LIBLZMA_LIBS="-L$DEPS/lib -llzma" \
        LIBSQLITE3_CFLAGS="-I$DEPS/include" LIBSQLITE3_LIBS="-L$DEPS/lib -lsqlite3 -lm -ldl"
fi
make -j"$(nproc)"
rm -rf "$OUT/root" && make install DESTDIR="$OUT/root"
# libsodium for libnacl, and the packages built earlier (same Python version, so the wheels still fit)
mkdir -p "$OUT/root$TARGET_PREFIX/lib"
cp -a "$DEPS"/lib/libsodium.so* "$OUT/root$TARGET_PREFIX/lib/"
for w in "$W"/wheels/*.whl; do [ -f "$w" ] && unzip -oq "$w" -d "$OUT/root$TARGET_PREFIX/lib/python3.14/site-packages"; done
echo "=== result"
ls "$OUT/root$TARGET_PREFIX"
${CROSS}readelf -h "$OUT/root$TARGET_PREFIX/bin/python3.14" | grep -E "Flags|Machine"
${CROSS}readelf -A "$OUT/root$TARGET_PREFIX/bin/python3.14" | grep -E "FP ABI"
${CROSS}readelf -d "$OUT/root$TARGET_PREFIX/bin/python3.14" | grep NEEDED
echo "=== BUILD DONE"
