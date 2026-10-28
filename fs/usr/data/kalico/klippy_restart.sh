# stop every klippy.py (stock and Kalico); the start.sh loop starts Kalico again
pids() {
    for p in /proc/[0-9]*; do
        { tr '\0' ' ' < $p/cmdline; } 2>/dev/null | grep -q "$1" && echo ${p#/proc/}
    done
}
kill $(pids 'klippy\.py') 2>/dev/null
i=0
while [ -n "$(pids 'klippy\.py')" ] && [ $i -lt 5 ]; do sleep 1; i=$((i + 1)); done
kill -9 $(pids 'klippy\.py') 2>/dev/null
if [ -z "$(pids '/usr/data/kalico/start\.sh')" ]; then
    cd /
    setsid nohup /usr/data/kalico/start.sh > /dev/null 2>&1 < /dev/null &
fi
sleep 5
pids 'klippy\.py' | wc -l
