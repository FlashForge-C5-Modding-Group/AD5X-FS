#!/usr/bin/env python3
# Probe ttyS4: passive listen, bootloader sync, Kalico identify at a few bauds
# usage: ifs_probe.py <port>
import os, sys, termios, time
sys.path.insert(0, '/usr/data/kalico/klipper/klippy')
import msgproto

port = sys.argv[1]
fd = os.open(port, os.O_RDWR | os.O_NOCTTY)

def setup(baud, parity):
    attr = termios.tcgetattr(fd)
    attr[0] = termios.INPCK if parity else 0
    attr[1] = 0
    attr[2] = termios.CS8 | termios.CREAD | termios.CLOCAL | (
        termios.PARENB if parity else 0)
    attr[3] = 0
    attr[4] = attr[5] = getattr(termios, 'B%d' % baud)
    attr[6][termios.VMIN] = 0
    attr[6][termios.VTIME] = 0
    termios.tcsetattr(fd, termios.TCSANOW, attr)
    termios.tcflush(fd, termios.TCIOFLUSH)

def listen(secs):
    out = b''
    end = time.time() + secs
    while time.time() < end:
        out += os.read(fd, 4096)
        time.sleep(0.005)
    return out

mp = msgproto.MessageParser()
identify = mp.create_command('identify offset=0 count=40')
frame = bytearray([len(identify) + 5, 0x10]) + bytearray(identify)
crc = msgproto.crc16_ccitt(frame)
frame += bytearray(crc) + b'\x7e'

setup(115200, False)
print('passive 115200 8N1:', listen(1.0).hex())
for baud in (115200, 230400, 57600):
    setup(baud, False)
    for _ in range(4):
        os.write(fd, b'\x7e' + frame)
        print('identify %d: %s' % (baud, listen(0.3).hex()))
setup(115200, True)
os.write(fd, b'C')
print('sync C 8E1:', listen(0.5).hex())
