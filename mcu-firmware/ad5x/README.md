# MCU firmware for the AD5X

Kalico firmware images for the three AD5X boards, built from `kalico-ad5x`:

| File | Board | Flashed with |
|---|---|---|
| `AD5X-mainboard.bin` | Mainboard (`/dev/ttyS2`) | `NationsCommand` (the chip's ROM bootloader) |
| `AD5X-eboard.hex` | Toolhead board (`/dev/ttyS5`) | `IAPCommand`, or the one-time hook in `startup.sh` (`/usr/data/kalico-fw/eboard.flash` holds the path of the `.hex`) |
| `AD5X-ifs.hex` | IFS (`/dev/ttyS4`) | `fs/usr/data/opencreator/mcu-flash/ifs_flash.sh` |

`config/` has the Kalico build config for each board. `VERSION` is the `kalico-ad5x` commit the images were built from, which is also what the boards report as their version.

To update the images, put the new files here, then:

```sh
sha256sum *.hex *.bin > SHA256SUMS
echo 8ee87b51 > VERSION   # the kalico-ad5x commit
```

How each board is flashed, and how to get back to the stock firmware, is in the OpenAD5X docs under MCU development and IFS.
