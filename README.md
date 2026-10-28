# ad5x-fs
Config and modules for the FlashForge AD5X running Kalico, with the IFS as an AFC unit.

## Contents
- `fs/usr/data/config-ad5x/`: printer config (`printer.base.cfg`, `printer.cfg`, `ad5x_home.cfg`, `ad5x_print.cfg`, `loadcell.cfg`, `moonraker.conf`) and `AFC/` (`AFC.cfg`, `AFC_Hardware-IFS.cfg`, `AFC_Macro_Vars.cfg`, `ifs_macros.cfg`)
- `fs/usr/data/opencreator/afc-ifs/`: `AFC_IFS.py` (the IFS unit for AFC) and `ad5x_filament_sensor.py`
- `fs/usr/data/opencreator/mcu-flash/`: `ifs_capture.py` and `ifs_catch.py`, flash the IFS MCU over its serial port
- `fs/usr/data/opencreator/loadcell/loadcell.sh`: bed load cell commands used by `loadcell.cfg`
- `mcu-firmware/ad5x/`: AD5X MCU firmware images with `SHA256SUMS`
