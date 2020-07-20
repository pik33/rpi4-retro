#!/bin/sh
DoExitAsm ()
{ echo "An error occurred while assembling $1"; exit 1; }
DoExitLink ()
{ echo "An error occurred while linking $1"; exit 1; }
echo Assembling retromalina
/usr/bin/as -o /home/pi/rpi4-retro/a64b/lib/aarch64-linux/retromalina.o  /home/pi/rpi4-retro/a64b/lib/aarch64-linux/retromalina.s
if [ $? != 0 ]; then DoExitAsm retromalina; fi
rm /home/pi/rpi4-retro/a64b/lib/aarch64-linux/retromalina.s
echo Assembling project1
/usr/bin/as -o /home/pi/rpi4-retro/a64b/lib/aarch64-linux/project1.o  /home/pi/rpi4-retro/a64b/lib/aarch64-linux/project1.s
if [ $? != 0 ]; then DoExitAsm project1; fi
rm /home/pi/rpi4-retro/a64b/lib/aarch64-linux/project1.s
echo Linking /home/pi/rpi4-retro/a64b/project1
OFS=$IFS
IFS="
"
/usr/bin/ld.bfd   --dynamic-linker=/lib/ld-linux-aarch64.so.1    -L. -o /home/pi/rpi4-retro/a64b/project1 /home/pi/rpi4-retro/a64b/link.res
if [ $? != 0 ]; then DoExitLink /home/pi/rpi4-retro/a64b/project1; fi
IFS=$OFS
