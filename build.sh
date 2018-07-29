#!/bin/bash 
KERNEL="4.17.11"
BUSY="1.29.1"
ARCH="x86_64" #default
TOP=$HOME/Linux/teeny-linux

#first stuff happening here.
mkdir -p $TOP
cd $TOP

#a bunch of helpfull functions
function DoQemu {
cd $TOP
qemu-system-$ARCH \
    -kernel obj/linux-x86-basic/arch/$ARCH/boot/bzImage \
    -initrd obj/initramfs-busybox-x86.cpio.gz \
    -nographic -append "console=ttyS0" -enable-kvm
}

function delete {
cd $TOP
rm -rf *
exit 1
}

function writeInit {
cat << EOF> init 
#!/bin/sh
 
mount -t proc none /proc
mount -t sysfs none /sys
 
echo -e '\nWelcome to Teeny Linux\n'
echo -e 'Amount of seconds to boot: '
cut -d' ' -f1 /proc/uptime
echo -e 'To shutdown and return to your CLI'
echo -e 'type poweroff -f or \n Ctrl+a C, then "quit"\n'
cat /proc/version
 
exec /bin/sh
EOF
}

function buildBusyBox {
cd $TOP
rm -rf busybox-$BUSY/
tar xjf busybox-$BUSY.tar.bz2
rm -rf obj/busybox-x86
cd $TOP/busybox-$BUSY
mkdir -pv ../obj/busybox-x86
make O=../obj/busybox-x86 defconfig
# do a static lib thing for busy, 
sed -i '/# CONFIG_STATIC is not set/c\CONFIG_STATIC=y' ../obj/busybox-x86/.config
cd ../obj/busybox-x86
make -j$(nproc)
make install
}

function makeInitramfs {
#Make the initramfs (first clean ofcourse)
rm -rf $TOP/initramfs
mkdir -pv $TOP/initramfs/x86-busybox
cd $TOP/initramfs/x86-busybox
mkdir -pv {bin,sbin,etc,proc,sys,usr/{bin,sbin}}
cp -av $TOP/obj/busybox-x86/_install/* .
writeInit
chmod +x init
find . -print0 \
    | cpio --null -ov --format=newc \
    | gzip -9 > $TOP/obj/initramfs-busybox-x86.cpio.gz
}


function makeKernel {
cd $TOP
rm -rf linux-$KERNEL/
rm -rf obj/linux-x86-basic
tar xJf linux-$KERNEL.tar.xz
#Make our Kernel
cd $TOP/linux-$KERNEL
make O=../obj/linux-x86-basic x86_64_defconfig
make O=../obj/linux-x86-basic kvmconfig
make O=../obj/linux-x86-basic -j$(nproc)
}


#process commandline arguments
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -arch|-cpu)
    ARCH="$2"
    shift; shift # past argument and value
    ;;-init|-makeInit|-makeinit)
    makeInitramfs
    DoQemu
    exit
    shift; shift # past argument and value
    ;;-d|-delete|-deleteall)
    delete
    shift; # past argument and value
    ;;
esac
done

#sets defaults if arguments are empty or incorrect
if [ -z $ARCH ]; then
    ARCH="x86_64"; fi
    
    
#Download if nececairy, clean an unclean build
if [ ! -f $TOP/linux-$KERNEL.tar.xz ]; then
    wget -c https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$KERNEL.tar.xz
fi
if [ ! -f $TOP/busybox-$BUSY.tar.bz2 ]; then
    wget -c https://busybox.net/downloads/busybox-$BUSY.tar.bz2
fi

if [ -f $TOP/obj/initramfs-busybox-x86.cpio.gz ]; then
    if [ ! -f $TOP/obj/linux-x86-basic/arch/x86_64/boot/bzImage ]; then
        makeKernel
    fi
    DoQemu
    exit
else
    if [ -f $TOP/obj/busybox-x86/busybox ]; then
        makeInitramfs
        if [ ! -f $TOP/obj/linux-x86-basic/arch/x86_64/boot/bzImage ]; then
            makeKernel
        fi
        DoQemu
        exit
    else
        buildBusyBox
        makeInitramfs
        if [ ! -f $TOP/obj/linux-x86-basic/arch/x86_64/boot/bzImage ]; then
            makeKernel
        fi
        DoQemu
        exit
        fi
    fi
    
fi

