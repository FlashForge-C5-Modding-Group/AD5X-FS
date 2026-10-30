#!/bin/sh
# Releases MCU boards from their boot stage whenever Klipper can't reach one
# (power-on, FIRMWARE_RESTART). Port of c5_bridge.py's wake from
# opencreator-tunnel; see config-docs/CREATOR5_MCU_WAKE.md.

LOG=/usr/data/logs/mcu-wake.log
PRINTER_LOG=/usr/data/openad5x/klipper/logs/printer.log
LOCK=/tmp/mcu-wake.lock
RETRY_MIN=7

exec 9>"$LOCK"
flock -n 9 || exit 0

ACK=$(printf '\006')
IDENTIFY='\176\010\020\001\000\050\136\237\176'
STOPPED=

log() {
    echo "$(date '+%F %T') $*" >> "$LOG"
}

# mcu name -> tty, Klipper baud, wake parity order
MACHINE=$(sed -n 's/^[[:space:]]*MACHINE=\([A-Za-z0-9]*\).*/\1/p' \
    /usr/prog/app_startup.sh /usr/prog/PROGRAM/runFirmwareExe.sh 2>/dev/null | head -n 1)
board() {
    if [ "$MACHINE" = AD5X ]; then
        # only the eboard has the Ready/A boot stage; ttyS2 is the mainboard
        # (boots straight into the app) and ttyS4 the IFS (RS485, its
        # bootloader speaks XMODEM, not Ready/A)
        case "$1" in
            eboard) echo "/dev/ttyS5 230400 N E" ;;
            *) return 1 ;;
        esac
        return 0
    fi
    case "$1" in
        eheaterboard|heaterboard) echo "/dev/ttyS4 230400 N E" ;;
        eboard) echo "/dev/ttyS5 460800 E N" ;;
        levelboard) echo "/dev/ttyS7 230400 N E" ;;
        *) return 1 ;;
    esac
}

klippy_pids() {
    for d in /proc/[0-9]*; do
        tr '\0' ' ' < "$d/cmdline" 2>/dev/null | grep -q 'klippy/klippy\.py' &&
            echo "${d#/proc/}"
    done
}

resume_klippy() {
    [ -n "$STOPPED" ] && kill -CONT $STOPPED 2>/dev/null
    STOPPED=
}

set_line() {
    if [ "$3" = E ]; then par="parenb -parodd"; else par="-parenb"; fi
    stty -F "$1" "$2" raw -echo cs8 -cstopb -crtscts clocal cread -inpck $par
}

# Sets GOT=1 if anything arrived; succeeds once "Ready" is seen.
wait_banner() {
    GOT=0
    tail=
    end=$(($(date +%s) + 4))
    while [ "$(date +%s)" -lt "$end" ]; do
        c=
        IFS= read -r -n 1 -t 0.2 c <&3 || [ -n "$c" ] || continue
        GOT=1
        tail="$tail$c"
        case "$tail" in *Ready*) return 0 ;; esac
        [ ${#tail} -gt 16 ] && tail=${tail#????????}
    done
    return 1
}

# Succeeds once byte $1 arrives; gives up after ~0.3 s of silence.
read_until() {
    idle=0 bytes=0
    while [ $idle -lt 6 ] && [ $bytes -lt 256 ]; do
        c=
        if IFS= read -r -n 1 -t 0.05 c <&3 || [ -n "$c" ]; then
            bytes=$((bytes + 1))
            [ "$c" = "$1" ] && return 0
        else
            idle=$((idle + 1))
        fi
    done
    return 1
}

send_ack() {
    for try in 1 2 3; do
        printf A >&3
        read_until "$ACK" && return 0
    done
    return 1
}

# Klipper answers an identify with a frame ending in 0x7e ("~").
probe() {
    n=0
    while [ $n -lt 256 ] && IFS= read -r -n 1 -t 0.05 c <&3; do
        n=$((n + 1))
    done
    printf "$IDENTIFY" >&3
    read_until "~"
}

wake() {
    name=$1 tty=$2 baud=$3
    shift 3
    STOPPED=$(klippy_pids)
    [ -n "$STOPPED" ] && kill -STOP $STOPPED
    saved=$(stty -g -F "$tty") || { resume_klippy; return; }
    exec 3<>"$tty"
    result="failed: no banner"
    for parity in "$@"; do
        set_line "$tty" 115200 "$parity"
        if wait_banner; then
            if send_ack; then
                result="ok (parity $parity)"
                break
            fi
            set_line "$tty" "$baud" N
            if probe; then
                result="ok (parity $parity, ack lost)"
                break
            fi
            result="failed: no ack"
        fi
        [ "$GOT" = 1 ] || break
    done
    exec 3<&-
    stty -F "$tty" "$saved"
    resume_klippy
    log "$name: wake $result"
}

# AD5X: start the eboard application before Klippy connects, and flash it first when
# /usr/data/kalico-fw/eboard.flash names a .hex. The bootloader only accepts IAPCommand while it
# waits for the 'A' (0x41), and answers ACK (0x06). 10-klipper.sh waits for the marker.
EBOARD=/dev/ttyS5
EBOARD_FLASH=/usr/data/kalico-fw/eboard.flash
EBOARD_READY=/tmp/openad5x-eboard-ready
IAP=/usr/prog/PROGRAM/control/1.1.1/IAPCommand
FLASH_LOGS=/usr/data/logs/openad5x

eboard_start() {
    stty -F $EBOARD 115200 cs8 -parenb -cstopb -crtscts clocal raw -echo || return 1
    exec 3<>$EBOARD
    ack=$(printf '\006')
    tries=0
    while [ $tries -lt 20 ]; do
        ready=
        i=0
        while [ $i -lt 10 ]; do
            if IFS= read -r -t 1 line <&3; then
                case "$line" in *Ready*) ready=1; break ;; esac
            fi
            i=$((i + 1))
        done
        if [ -z "$ready" ]; then
            log "eboard: no Ready, application already running"
            exec 3<&-
            return 0
        fi
        if [ -f "$EBOARD_FLASH" ]; then
            hex=$(cat "$EBOARD_FLASH")
            rm -f "$EBOARD_FLASH"
            exec 3<&-
            mkdir -p $FLASH_LOGS
            log "eboard: flashing $hex"
            $IAP "$hex" $EBOARD > $FLASH_LOGS/eboard-flash.log 2>&1
            log "eboard: IAPCommand exit $?"
            stty -F $EBOARD 115200 cs8 -parenb -cstopb -crtscts clocal raw -echo
            exec 3<>$EBOARD
            continue
        fi
        printf '\101' >&3
        j=0
        while [ $j -lt 20 ]; do
            if IFS= read -r -n 1 -t 1 c <&3 && [ "$c" = "$ack" ]; then
                log "eboard: application started"
                exec 3<&-
                return 0
            fi
            j=$((j + 1))
        done
        tries=$((tries + 1))
    done
    log "eboard: no ACK"
    exec 3<&-
    return 1
}

if [ "$MACHINE" = AD5X ]; then
    rm -f "$EBOARD_READY"
    eboard_start
    touch "$EBOARD_READY"
fi

log "started"
tail -n 0 -F "$PRINTER_LOG" 2>/dev/null | {
    trap 'resume_klippy; exit' INT TERM HUP
    while IFS= read -r line; do
        case "$line" in
            *"mcu '"*"': Timeout on connect"*) ;;
            *) continue ;;
        esac
        name=${line#*mcu \'}
        name=${name%%\'*}
        b=$(board "$name") || continue
        eval "last=\${last_$name:-0}"
        [ $(($(date +%s) - last)) -lt $RETRY_MIN ] && continue
        log "$name: identify unanswered"
        wake "$name" $b
        eval "last_$name=$(date +%s)"
    done
}
