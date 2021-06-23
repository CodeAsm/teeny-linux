#!/bin/sh

KERNEL="5.12.13"                #Kernel release number. (or see cli options)
V="${KERNEL:0:1}"               #Kernel version for folder (probably breaks when 10 or larger)
KTYPE="xz"                      #gz used by RC, xz by stable releases, but should work.
                                #if posible, I would prever xz for its size and decompress seed
BUSY="1.32.1"                   #busybox release number
ARCH="x86_64"                   #default arch
ARC="x86"                       #short arch (can I use grep for this?)
TOP=$HOME/Projects/Emulation/Linux/bin  #location for the build, change this for your location

COMPILER="CC=musl-gcc"          #compiler pre. (2020 Musl fix for x86, might break other distro if musl missing)
IP="192.168.66.6"               #IP to be used by the virtual machine
GATEWAY="192.168.66.1"          #default gateway to be used
DNS="1.1.1.1"                   #default DNS, use 8.8.8.8 if you want silly google
HOSTNAME="TeenyQemuBox"         #hostname
MODULEURL=$TOP/../teeny-linux/modules/        #modprobe url
LOGINREQUIRED="/bin/login"      #replace with /bin/sh for no login required, /bin/login needed else 
                                #seems one can simply Ctrl+C out of login tho
