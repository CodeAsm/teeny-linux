#!/bin/sh
KERNEL="5.11.13"	                #Kernel release number. (or see cli options)
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

#DO NOT EDIT BELOW it should not be nececairy.
#-----------------------------------------------------------
MAKEINIT=false                  #we dont want to overdo a makeinit, used internaly
MODULE=false                    #add modules to linux (asuming kernel already supports this)

#first stuff happening here.
mkdir -p $TOP
cd $TOP

#a bunch of helpfull functions
#----------------------------------------------------------------------
function DoQemu {
cd $TOP
qemu-system-$ARCH \
    -m 2G \
    -kernel obj/linux-$ARC/arch/$ARCH/boot/bzImage \
    -initrd obj/initramfs-busybox-$ARC.cpio.gz \
    -nographic -append "console=ttyS0" $NET $OPTION
}

#----------------------------------------------------------------------
function delete {
cd $TOP
mv linux-$KERNEL.tar.$KTYPE ../
mv busybox-$BUSY.tar.bz2 ../
rm -rf *
mv ../linux-$KERNEL.tar.$KTYPE linux-$KERNEL.tar.$KTYPE
mv ../busybox-$BUSY.tar.bz2 busybox-$BUSY.tar.bz2
exit 1
}

#----------------------------------------------------------------------
function writeInit {
cat << EOF> init 
#!/bin/sh
syslogd 
mount -t devtmpfs devtmpfs /dev
mount -t proc none /proc
mount -t sysfs none /sys
 
 hostname 
/sbin/mdev -s
/sbin/ifconfig lo 127.0.0.1 netmask 255.0.0.0 up
/sbin/ifconfig eth0 up $IP netmask 255.255.255.0 up
/sbin/route add default gw $GATEWAY
hostname $HOSTNAME
echo -e '\nWelcome to Teeny Linux\n'
echo -e 'Amount of seconds to boot: '
cut -d' ' -f1 /proc/uptime
echo -e 'To shutdown and return to your CLI'
echo -e 'type poweroff -f or \n Ctrl+a C, then "quit"\n'
cat /proc/version
ifconfig eth0 | grep -B1 'inet addr' | grep 'inet'

/usr/bin/setsid /bin/cttyhack $LOGINREQUIRED
exec $LOGINREQUIRED
EOF
}

#----------------------------------------------------------------------
function copytoimage {      #This function will copy nececairy files into the initramfs

# modules option
if $MODULE ; then
    mkdir -pv lib/modules/$KERNEL/extra
    cp $MODULEURL/hello.ko lib/modules/$KERNEL/extra/hello.ko
fi

# the extra builded files to be included into the initramfs
if [ -d $TOP/build/ ]; then
    cp -r $TOP/build/. $TOP/initramfs/$ARC-busybox/
fi

#add user?
cat << EOF> $TOP/initramfs/$ARC-busybox/etc/passwd
root:LTMW6A/nz.KWI:0:0:root:/root:/bin/sh
EOF
}

#----------------------------------------------------------------------
function buildBusyBox {
cd $TOP
rm -rf busybox-$BUSY/
tar xjf busybox-$BUSY.tar.bz2
rm -rf obj/busybox-$ARC
cd $TOP/busybox-$BUSY
mkdir -pv ../obj/busybox-$ARC
if [ $ARCH != "x86_64" ]; then
    make O=../obj/busybox-$ARC ARCH=$ARCH CROSS_COMPILE=$COMPILER defconfig
else
    make O=../obj/busybox-$ARC defconfig $COMPILER
fi
# do a static lib thing for busy, 
sed -i '/# CONFIG_STATIC is not set/c\CONFIG_STATIC=y' ../obj/busybox-$ARC/.config
#for musl we experimentaly determined these to be nececairy


cd ../obj/busybox-$ARC
if [ $ARCH != "x86_64" ]; then
    make -j$(nproc) ARCH=$ARCH CROSS_COMPILE=$COMPILER
else
    make -j$(nproc) $COMPILER
fi
make install $COMPILER
}

function makeNewInitramfs {
#Make the initramfs (first clean ofcourse)
rm -rf $TOP/initramfs
mkdir -pv $TOP/initramfs/$ARC-busybox
cd $TOP/initramfs/$ARC-busybox
mkdir -pv {bin,sbin,root,etc,proc,sys,usr/{bin,sbin,local/{bin,lib}}}
mkdir -pv {var/{run,lib/dpkg},etc/network/{if-down.d,if-up.d,if-down.d,if-post-down.d,if-post-up.d,if-pre-down.d,if-pre-up.d}}
touch var/lib/dpkg/status
 
makeInitramfs
}

function makeInitramfs {
cd $TOP/initramfs/$ARC-busybox
cp -av $TOP/obj/busybox-$ARC/_install/* .
#add new files to copy here?
writeInit
copytoimage
cd $TOP/initramfs/$ARC-busybox/root
cat << EOF> .bashrc
#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
alias ls='ls --color=auto'


alias today='date +"%d-%m-%Y"'
alias todaytime='date +"%d-%m-%Y %H:%M"'

  PS1="\[\033[35m\]\t\[\033[m\] [\[\033[1;31m\]\u\[\033[0m\]@\[\e[1;34m\]\h\[\e[0m\]:\[\e[94m\]\w\[\e[0m\]]\\$ \[\e[m\]" 
  
EOF
cat << EOF> .bash_profile
PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin:tools
EOF

cat << EOF> hello.c
#include <stdio.h>
int main()
{
	printf("Hello world.\n");
	return 0;	
}
EOF

cd $TOP/initramfs/$ARC-busybox
# DNS entry
echo nameserver $DNS > etc/resolv.conf

chmod +x init
if [ -f $TOP/obj/busybox-$ARC/busybox ]; then
    find . -print0 \
        | cpio --null -ov --format=newc \
        | gzip -9 > $TOP/obj/initramfs-busybox-$ARC.cpio.gz
else
echo "[ error ] busybox is missing"
exit 1;
fi
}

#----------------------------------------------------------------------

function makeKernel {
cd $TOP
rm -rf linux-$KERNEL/
rm -rf obj/linux-$ARC
if [ ! $KTYPE == "gz" ]; then #for gz we need xvf, due to RC being diferent
    tar xJf linux-$KERNEL.tar.$KTYPE
else
    tar xvf linux-$KERNEL.tar.$KTYPE
fi
#Make our Kernel
cd $TOP/linux-$KERNEL

# Former PPC config was here.

make mrproper
make O=../obj/linux-$ARC x86_64_defconfig
make O=../obj/linux-$ARC kvm_guest.config
make O=../obj/linux-$ARC -j$(nproc)

}

#----------------------------------------------------------------------
#process commandline arguments
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -arch|-cpu)
    ARCH="$2"
    ARC="$2"
    shift; shift # past argument and value
    ;;-init|-makeInit|-makeinit)
    MAKEINIT=true
    ARCH="x86_64"
    shift; # past argument and value
    ;;-d|-delete|-deleteall)
    delete
    shift; # past argument and value
    ;;-k|-kernel)
    KERNEL="$2"
    shift; shift
    ;;-nologin|-nl)
    LOGINREQUIRED="/bin/sh"
    MAKEINIT=true
    shift;
    ;;-net)
    NET="-net nic,model=e1000,macaddr=$2 -net bridge,br=br0"
    shift; shift
    ;;-mod|-module)
    MODULE=true
    MAKEINIT=true
    shift;
    ;;-option)
    OPTION="$2"
    shift; shift
    ;;
esac
done

#sets defaults if arguments are empty or incorrect
if [ -z $ARCH ]; then
    ARCH="x86_64"; fi
    
cd $TOP
#Download if nececairy, clean an unclean build
if [ ! -f $TOP/linux-$KERNEL.tar.$KTYPE ]; then #Maybe now partial downloads work?
        wget -c https://cdn.kernel.org/pub/linux/kernel/v$V.x/linux-$KERNEL.tar.$KTYPE
fi

if [ ! -f "$TOP/busybox-$BUSY.tar.bz2" ]; then
        wget -c https://busybox.net/downloads/busybox-$BUSY.tar.bz2
fi


if [ $ARCH == "ppc" ]; then #this is to have a full arch name, but working functions
    ARCHF="powerpc"
else
    ARCHF=$ARCH
fi

if [ $MAKEINIT == "true" ]; then
    makeNewInitramfs
fi
    
if [ -f "$TOP/obj/initramfs-busybox-$ARC.cpio.gz" ]; then
    if [ ! -f $TOP/obj/linux-$ARC/arch/$ARCHF/boot/bzImage ]; then
        makeKernel
    fi
    DoQemu
    exit
else
    if [ -f "$TOP/obj/busybox-$ARC/busybox" ]; then
        makeNewInitramfs
        if [ ! -f "$TOP/obj/linux-$ARC/arch/$ARCHF/boot/bzImage" ]; then
            makeKernel
        fi
        DoQemu
        exit
    else
        buildBusyBox
        makeNewInitramfs
        if [ ! -f "$TOP/obj/linux-$ARC/arch/$ARCHF/boot/bzImage" ]; then
            makeKernel
        fi
        DoQemu
        exit
        fi
    fi
    
fi

