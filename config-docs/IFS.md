# IFS as an AFC unit

The IFS (the four-lane feeder) runs on its own Kalico MCU (`[mcu ifs]`, serial `/dev/ttyS4`, 115200) and is an `[AFC_IFS IFS_1]` unit for AFC. The unit is `AFC_IFS.py`, installed next to `AFC_HTLF.py`. The sensor entries come from `ad5x_filament_sensor.py`. Configuration is in `config/AFC/AFC_Hardware-IFS.cfg`, the macros in `config/AFC/ifs_macros.cfg`.

Behaviour follows the stock firmware, decoded from `firmwareExe` (see the OpenAD5X docs, section IFS).

## What it does

- **Selector:** one stepper turns a cam with a lane every 90°. It homes on `home_pin` at 70.43°/s with no ramp, then moves to the lane's slot. After a load it parks between slots so no lane is held.
- **Feed motor:** one stepper pushes the selected lane. It is off while the extruder pulls the filament, and is switched off as soon as a move ends. Normal feed is 20 mm/s.
- **Lane sensors:** four ADC "silk" sensors tell whether a spool is in each lane. Limits can be calibrated per lane.
- **Toolhead sensor:** `fill_sensor` (the `filamentValue` ADC on the toolhead board). Filament is present at or below `present_below` (0.30) or at or above `present_above` (0.72).
- **Purge chute:** the head enters along X, then Y to 220, then Y to 230.5, and leaves along Y first.

## Flows

| Flow | What happens |
|---|---|
| Spool inserted (not printing), toolhead empty | The lane feeds until the toolhead sensor triggers (up to `auto_load_max`), then pulls back `park_dist` and releases |
| Spool inserted, filament already in the toolhead | The lane feeds a fixed `auto_load_max`, then pulls back `park_dist` (the stock behaviour; the sensor cannot be used) |
| Tool change | Cut and unload the old lane, park in the chute, feed the new lane to the toolhead sensor, flush with the lane pushing in step with the extruder (at least 60 mm, 90 mm default), wipe, release the selector |
| First tool of a print, already loaded | Park in the chute and flush with the lane pushing, wipe, flush again, wipe, then continue |
| End or cancel of a print | `END_PRINT` and `CANCEL_PRINT` call `ADX_END_UNLOAD`, which cuts and unloads the lane in the toolhead while the nozzle is still hot. A failure never stops the end macro |

## The end of print unload switch

The web UI's filament sensors list has an entry named `end_unload`. Its on/off switch turns the unload at the end of a print on or off. The setting is saved in `/usr/data/openad5x/klipper/config/AFC/ifs_options.json`, and the default comes from the `end_unload` option. `ADX_END_UNLOAD_SET ENABLE=0|1` does the same from a console, and with no value it shows the current state.

## Options of `[AFC_IFS IFS_1]`

Set in `AFC_Hardware-IFS.cfg`:

| Option | Value | Meaning |
|---|---|---|
| `home_pin` | `^!ifs:PB9` | Selector home sensor |
| `slot_angle`, `cam_angle` | 90, 45 | Degrees per lane slot and cam offset |
| `silk_pins` | `ifs:PC0, PC2, PB12, PB14` | Lane sensors |
| `speed_pins` | `ifs:PC1, PC3, PB13, PB15` | Roller speed sensors, used only when `odometer_enable` is True |
| `odometer_enable` | `False` | Pause when a roller stands still while extruding |
| `end_unload` | `True` | Unload at the end of a print |
| `selector_movement_speed` | 70.43 | Selector speed in degrees per second |
| `long_moves_speed`, `short_moves_speed` | 20 | Feed speed in mm/s |
| `long_moves_accel`, `short_moves_accel` | 500 | Feed acceleration |
| `tool_max_unload_attempts` | 0 | Stock never retries unloading with the extruder |

Read by the code with these defaults when not set:

| Option | Default | Meaning |
|---|---|---|
| `auto_load` | `True` | Load a lane when a spool is inserted |
| `auto_load_max` | 650 | Feed distance for auto-load (mm) |
| `park_dist` | 100 | Pull back after auto-load (mm) |
| `load_feed`, `load_retry_feed`, `load_backoff` | 600, 500, 5 | Feed to the toolhead sensor during a load, the retry feed and the back-off between them (mm) |
| `unload_cut_dist`, `unload_ifs_dist` | 60, 70 | Retract lengths when cutting and unloading (mm) |
| `chute_x`, `chute_y`, `chute_y_out` | 52.5, 230.5, 220 | Purge chute position |
| `brush_x_min`, `brush_x_max`, `brush_x_out`, `brush_count` | 65, 73, 78, 2 | Brush wipe |
| `cut_approach_y` | 10 | Y of the approach to the cutter |
| `rehome_on_select` | `True` | Re-home the selector when a different lane is selected |
| `tool_sensor` | `fill_sensor` | Toolhead sensor |
| `silk_file` | `/usr/data/openad5x/klipper/config/AFC/ifs_silk.json` | Saved silk calibration |
| `options_file` | `/usr/data/openad5x/klipper/config/AFC/ifs_options.json` | Saved switch setting |

## Commands

Typed in the console (`ADX_` commands) or as buttons (`IFS_` macros in `ifs_macros.cfg`).

| Command | What it does |
|---|---|
| `IFS_SELECT_LANE LANE=1-4` | Clamp a lane onto the feed wheel |
| `IFS_RELEASE` | Release the clamped lane |
| `IFS_FEED`, `IFS_RETRACT LANE= DISTANCE=` | Move a lane forward or back |
| `IFS_LOAD LANE=1-4 [TEMP=]` | Stock load wizard: heat, clear old filament, feed to the head, flush (`ADX_LOAD_HEAD`) |
| `IFS_UNLOAD_TOOL LANE=1-4 [TEMP=]` | Cut and unload the lane in the toolhead |
| `IFS_CHANGE_TOOL LANE=1-4 [TEMP=]` | Change to a lane |
| `IFS_SET_LOADED LANE=1-4`, `IFS_UNSET_LOADED` | Tell AFC what is in the toolhead |
| `IFS_RECOVER_LANE LANE=1-4` | Recover a lane after a failed move |
| `IFS_SILK_STATUS`, `IFS_SILK_CALIBRATE`, `IFS_SILK_RESET` | Lane sensor values and calibration (`ADX_SILK_STATUS`, `ADX_SILK_CALIBRATE LANE= STATE=empty\|present`, `ADX_SILK_SET`, `ADX_SILK_RESET`) |
| `ADX_PARK`, `ADX_POOP`, `ADX_BRUSH`, `ADX_CUT` | The chute park, purge, brush wipe and cutter approach that AFC calls |
| `ADX_END_UNLOAD`, `ADX_END_UNLOAD_SET` | Unload at the end of a print, and the switch for it |
