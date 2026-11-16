#!/usr/bin/env python3
# Run IFSCommand against a pty acting as the IFS bootloader and save its frames
# usage: ifs_capture.py <IFSCommand> <file.hex> <out.frames>
#
# Copyright (C) 2026  sterling motuz <Sterling@dexabyte.ca>
#
# Made for the OpenAD5X project
#
# This file may be distributed under the terms of the MIT license.
import os, pty, select, subprocess, sys, tty

ifscmd, hexfile, out = sys.argv[1:4]
master, slave = pty.openpty()
tty.setraw(master)
name = os.ttyname(slave)
logf = open(out + '.log', 'wb')
proc = subprocess.Popen([ifscmd, hexfile, name], stdout=logf,
                        stderr=subprocess.STDOUT)
buf = b''
frames = []
started = False
eot = False
# IFSCommand flushes after sending 'C', so ACK until the first frame arrives
while not eot:
    r, _, _ = select.select([master], [], [], 0.1 if not started else 10.0)
    if not r:
        if not started and proc.poll() is None:
            os.write(master, b'\x06')
            continue
        break
    try:
        buf += os.read(master, 4096)
    except OSError:
        break
    while buf:
        if buf[0] == 0x43:
            buf = buf[1:]
        elif buf[0] == 0x01:
            started = True
            if len(buf) < 1030:
                break
            frames.append(buf[:1030])
            buf = buf[1030:]
            os.write(master, b'\x06')
        elif buf[0] == 0x04:
            os.write(master, b'\x06')
            eot = True
            break
        else:
            print('unexpected byte %#x' % buf[0])
            buf = buf[1:]
try:
    proc.wait(timeout=30)
except subprocess.TimeoutExpired:
    proc.kill()
with open(out, 'wb') as f:
    for fr in frames:
        f.write(fr)
print('frames', len(frames), 'eot', eot)
if not frames or not eot:
    sys.exit(1)
