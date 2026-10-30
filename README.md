# ad5x-fs
Config and modules for the FlashForge AD5X running Kalico, with the IFS as an AFC unit. Documentation is in [openad5x](https://github.com/FlashForge-C5-Modding-Group/openad5x).

## Contents
- `fs/usr/data/openad5x/firmware/firmwareExe`, `startup/`, `version.txt`: the boot. `firmwareExe` brings the network up and runs `startup/startup.sh`, which starts every script in `startup/scripts/` (NaN byte, clock, Entware, toolhead board, Klippy, Moonraker, nginx, camera, GrumpyScreen). `10-klipper.sh` keeps Klippy running; `klippy_restart.sh` restarts it
- `fs/usr/data/config/`: printer config (`printer.base.cfg`, `printer.cfg`, `ad5x_home.cfg`, `ad5x_print.cfg`, `loadcell.cfg`, `moonraker.conf`) and `AFC/` (`AFC.cfg`, `AFC_Hardware-IFS.cfg`, `AFC_Macro_Vars.cfg`, `ifs_macros.cfg`)
- `fs/usr/data/openad5x/afc-ifs/`: `AFC_IFS.py` (the IFS unit for AFC) and `ad5x_filament_sensor.py`
- `fs/usr/data/openad5x/mcu-flash/`: `ad5x-mcu-flash` (flashes the mainboard and IFS live from a folder of `mcu-firmware/ad5x` images, and stages the eboard for the next power cycle), and `ifs_capture.py`, `ifs_catch.py`, `ifs_flash.sh`, `ifs_probe.py`, which flash the IFS MCU over its serial port
- `fs/usr/data/openad5x/loadcell/loadcell.sh`: bed load cell commands used by `loadcell.cfg`
- `mcu-firmware/ad5x/`: AD5X MCU firmware images with `SHA256SUMS`, and the Kalico build configs in `config/`
- `build/python/`: scripts that build the AD5X Python package (Python, the packages Kalico and Moonraker need, Moonraker, and `c_helper.so`), with a README
- `build/moonraker`, `build/fluidd`: the older Moonraker and Fluidd packages
- `config-docs/`: feature docs for the AFC and IFS config (`IFS.md`)
