# ad5x-fs
Config and modules for the FlashForge AD5X running Kalico, with the IFS as an AFC unit. Documentation is in [openad5x](https://github.com/FlashForge-C5-Modding-Group/openad5x).

## Contents
- `fs/usr/prog/openad5x/startup.sh` and `fs/usr/data/openad5x/startup.d/`: printer startup and its drop-in scripts (Entware, camera, Moonraker, nginx, GrumpyScreen)
- `fs/usr/data/kalico/`: `start.sh` (keeps Klippy running) and `klippy_restart.sh`
- `fs/usr/data/config-ad5x/`: printer config (`printer.base.cfg`, `printer.cfg`, `ad5x_home.cfg`, `ad5x_print.cfg`, `loadcell.cfg`, `moonraker.conf`) and `AFC/` (`AFC.cfg`, `AFC_Hardware-IFS.cfg`, `AFC_Macro_Vars.cfg`, `ifs_macros.cfg`)
- `fs/usr/data/opencreator/afc-ifs/`: `AFC_IFS.py` (the IFS unit for AFC) and `ad5x_filament_sensor.py`
- `fs/usr/data/opencreator/mcu-flash/`: `ifs_capture.py`, `ifs_catch.py`, `ifs_flash.sh`, `ifs_probe.py`, flash the IFS MCU over its serial port
- `fs/usr/data/opencreator/loadcell/loadcell.sh`: bed load cell commands used by `loadcell.cfg`
- `mcu-firmware/ad5x/`: AD5X MCU firmware images with `SHA256SUMS`, and the Kalico build configs in `config/`
- `build/`: scripts that build the Fluidd and Moonraker packages
