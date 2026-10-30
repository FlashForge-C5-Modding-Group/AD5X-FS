# flash /usr/data/kalico-fw/ifs.hex into a running Kalico IFS on ttyS4
set -e
PY=/usr/data/openad5x/klipper/klippy-env/bin/python
cd /usr/data/kalico-fw
md5sum ifs.hex
$PY ifs_capture.py /usr/prog/PROGRAM/control/1.1.1/IFSCommand ifs.hex ifs.frames
$PY -c "
import os,termios
fd=os.open('/dev/ttyS4',os.O_RDWR|os.O_NOCTTY)
a=termios.tcgetattr(fd); a[0]=0;a[1]=0;a[2]=termios.CS8|termios.CREAD|termios.CLOCAL;a[3]=0;a[4]=a[5]=termios.B115200
termios.tcsetattr(fd,termios.TCSANOW,a)
os.write(fd,b'~ \x1c Request Serial Bootloader!! ~'); termios.tcdrain(fd); print('request sent')
"
$PY ifs_catch.py /dev/ttyS4 ifs.frames ${1:-20}
