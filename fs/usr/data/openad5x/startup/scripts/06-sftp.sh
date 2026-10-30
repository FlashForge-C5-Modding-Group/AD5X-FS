#!/bin/sh
# SFTP: dropbear runs /usr/libexec/sftp-server, which the read-only root can't hold.
# A copy of dropbear pointing at Entware's sftp-server (a path of the same length) is
# bind-mounted over it and the listener restarted.
LAUNCHER_LOG="/tmp/openad5x.log"
SFTP=/opt/libexec/sftp-server
STOCK=/usr/sbin/dropbear
COPY=/usr/data/openad5x/bin/dropbear-sftp

strs() { strings "$@" 2>/dev/null || busybox strings "$@"; }

log_launcher() {
    echo "$1" >> "$LAUNCHER_LOG"
}

# 05-entfix.sh mounts /opt in parallel with this script
i=0
while [ ! -x "$SFTP" ] && [ $i -lt 60 ]; do
    sleep 1
    i=$((i + 1))
done
[ -x "$SFTP" ] || { log_launcher "SFTP: $SFTP missing (opkg install openssh-sftp-server)"; exit 0; }
grep -q " $STOCK " /proc/mounts && exit 0

off=$(strs -t d "$STOCK" | sed -n 's#^ *\([0-9]*\) /usr/libexec/sftp-server$#\1#p' | head -n 1)
[ -n "$off" ] || { log_launcher "SFTP: dropbear has no sftp-server path to patch"; exit 0; }
mkdir -p "${COPY%/*}"
cp "$STOCK" "$COPY.tmp" || exit 0
printf /opt | dd of="$COPY.tmp" bs=1 seek="$off" conv=notrunc 2>/dev/null
if [ "$(wc -c < "$COPY.tmp")" = "$(wc -c < "$STOCK")" ] &&
    strs -t d "$COPY.tmp" | grep -q "^ *$off /opt/libexec/sftp-server$"; then
    chmod 755 "$COPY.tmp" && mv "$COPY.tmp" "$COPY"
else
    rm -f "$COPY.tmp"
    log_launcher "SFTP: could not patch dropbear"
    exit 0
fi

mount --bind "$COPY" "$STOCK" || exit 0
/etc/init.d/S50dropbear restart >/dev/null 2>&1
log_launcher "SFTP enabled"
