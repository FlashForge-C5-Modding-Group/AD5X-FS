# AD5X Python package

Builds the package the installer puts on the AD5X: Python 3.14.4 for the printer's CPU, the packages Kalico and Moonraker need, Moonraker itself, and Kalico's `c_helper.so`. The package is `ad5x-python-3.14.4-mipsel.tar.gz`, with a `.sha256` next to it. It is not kept in git. It is published as a release asset of this repository, and `make-usb.sh` can also copy it onto the installer stick (`PYTHON_PACKAGE=...`).

It unpacks into two folders, `python/` and `moonraker/`, which the installer puts under `/usr/data/openad5x/`.

## What it builds for

The same format as FlashForge's own programs (`firmwareExe`, `python3.8`, `busybox`, `libc`): MIPS32r2, NaN2008, hard-float FP64, glibc 2.33. It needs only `libc`, `libm`, `libdl`, `libpthread`, `libutil` and `libatomic.so.1`, which the printer already has.

## What you need

A Linux machine or WSL with `python3` (the **same minor version as the target**, 3.14, because a cross-built Python needs a matching Python to build with), `make`, `curl`, `tar`, `xz`, `unzip`, `patch`, `perl` and `git`. It needs no native C compiler.

The Ingenic cross toolchain, extracted so that `~/toolchain/mips-xburst2-linux-toolchain-r6.0.0/bin/mips-xburst2-linux-gnu-gcc` exists (`mips-xburst2-linux-toolchain-r6.0.0.tar.bz2`, Ingenic's public FTP). Extract it with Python's `tarfile` if `bzip2` is not installed.

All work happens under `~/pybuild`.

## Order

```sh
bash build_python.sh      # zlib, libffi, OpenSSL, bzip2, xz, SQLite, libsodium, then Python itself
bash build_pkgs.sh        # cffi, greenlet, markupsafe, jinja2, pyserial, pycparser
bash build_numpy.sh       # numpy
bash build_mr_pkgs.sh <moonraker-commit>   # pillow, tornado, streaming-form-data and the other packages Moonraker needs
bash build_chelper.sh     # Kalico's c_helper.so, from a fresh clone of kalico-ad5x main
OUT_DIR=/some/folder bash package_python.sh   # trims a copy and writes the tarball and its .sha256
```

Libraries that are already built are skipped when a script is run again, but Python itself is rebuilt each time, which wipes its `site-packages`. `build_python.sh` puts the wheels saved by the earlier scripts back, so the order above only matters on a first build.

## Versions

| Part | Version |
|---|---|
| Python | 3.14.4 |
| zlib, libffi, OpenSSL | 1.3.1, 3.4.6, 3.0.16 (linked in statically) |
| bzip2, xz, SQLite | 1.0.8, 5.4.6, 3.54.1 (linked in statically) |
| libsodium | 1.0.20 (shared, in `python/lib`, for `libnacl`) |
| numpy | 2.3.5 |
| Moonraker | the commit given to `build_mr_pkgs.sh` and `package_python.sh` (currently `b559b9a81161f958a43c2f527b6ad96f73310d5d`) |

## When it has to be rebuilt

- **Kalico's C code changes.** The installer compares a fingerprint of `klippy/chelper/*.c *.h` with the one stored in the package (`python/chelper/SOURCES.sha256`), and stops if they differ, so a stale `c_helper.so` is never used. Run `build_chelper.sh` and `package_python.sh` again.
- **A new Moonraker commit or package version.** Change the commit in `package_python.sh`, run `build_mr_pkgs.sh` with it, and package again.

## Not tested here

None of this has been run on an AD5X. The PC cannot run MIPS programs, so the first real run is on the printer.
