#!/bin/bash 
KERNEL="4.19"
BUSY="1.29.3"
ARCH="x86_64" #default
ARC="x86"
TOP=$HOME/Linux/teeny-linux
COMPILER="powerpc-linux-gnu-"

#first stuff happening here.
mkdir -p $TOP
cd $TOP

#a bunch of helpfull functions
function DoQemu {
cd $TOP
qemu-system-$ARCH \
    -kernel obj/linux-$ARC-basic/arch/$ARCHF/boot/bzImage \
    -initrd obj/initramfs-busybox-$ARC.cpio.gz \
    -nographic -append "console=ttyS0" #-enable-kvm
}

function delete {
cd $TOP
mv linux-$KERNEL.tar.xz ../linux-$KERNEL.tar.xz
mv busybox-$BUSY.tar.bz2 ../busybox-$BUSY.tar.bz2
rm -rf *
mv ../linux-$KERNEL.tar.xz linux-$KERNEL.tar.xz
mv ../busybox-$BUSY.tar.bz2 busybox-$BUSY.tar.bz2
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
rm -rf obj/busybox-$ARC
cd $TOP/busybox-$BUSY
mkdir -pv ../obj/busybox-$ARC
if [ $ARCH != "x86_64" ]; then
    make O=../obj/busybox-$ARC ARCH=$ARCH CROSS_COMPILE=$COMPILER defconfig
else
    make O=../obj/busybox-$ARC defconfig
fi
# do a static lib thing for busy, 
sed -i '/# CONFIG_STATIC is not set/c\CONFIG_STATIC=y' ../obj/busybox-$ARC/.config
cd ../obj/busybox-$ARC
if [ $ARCH != "x86_64" ]; then
    make -j$(nproc) ARCH=$ARCH CROSS_COMPILE=$COMPILER
else
    make -j$(nproc)
fi
make install
}

function makeInitramfs {
#Make the initramfs (first clean ofcourse)
rm -rf $TOP/initramfs
mkdir -pv $TOP/initramfs/$ARC-busybox
cd $TOP/initramfs/$ARC-busybox
mkdir -pv {bin,sbin,etc,proc,sys,usr/{bin,sbin}}
cp -av $TOP/obj/busybox-$ARC/_install/* .
writeInit
chmod +x init
find . -print0 \
    | cpio --null -ov --format=newc \
    | gzip -9 > $TOP/obj/initramfs-busybox-$ARC.cpio.gz
}


function makeKernel {
cd $TOP
rm -rf linux-$KERNEL/
rm -rf obj/linux-$ARC-basic
tar xJf linux-$KERNEL.tar.xz
#Make our Kernel
cd $TOP/linux-$KERNEL

if [ $ARCH == "ppc" ]; then
#for ppc, we need to make a selection somday
#make O=../obj/linux-$ARC-basic ARCH=$ARCHF CROSS_COMPILE=$COMPILER g5_defconfig
# Write out Linux kernel .config file
mkdir "${TOP}"/obj/linux-$ARC-basic/
#touch "${TOP}"/obj/linux-$ARC-basic/.config
cat << EOF> "${TOP}"/obj/linux-$ARC-basic/.config
CONFIG_EXPERIMENTAL=y
CONFIG_SWAP=y
CONFIG_SYSVIPC=y
CONFIG_BSD_PROCESS_ACCT=y
CONFIG_BSD_PROCESS_ACCT_V3=y
CONFIG_IKCONFIG=y
CONFIG_IKCONFIG_PROC=y
CONFIG_SYSFS_DEPRECATED=y
CONFIG_RELAY=y
CONFIG_EMBEDDED=y
CONFIG_SYSCTL_SYSCALL=y
CONFIG_KALLSYMS=y
CONFIG_HOTPLUG=y
CONFIG_PRINTK=y
CONFIG_BUG=y
CONFIG_ELF_CORE=y
CONFIG_BASE_FULL=y
CONFIG_FUTEX=y
CONFIG_EPOLL=y
CONFIG_SHMEM=y
CONFIG_SLAB=y
CONFIG_VM_EVENT_COUNTERS=y
CONFIG_MODULES=y
CONFIG_MODULE_UNLOAD=y
CONFIG_KMOD=y
CONFIG_BLOCK=y
CONFIG_IOSCHED_AS=y
CONFIG_IOSCHED_DEADLINE=y
CONFIG_IOSCHED_CFQ=y
CONFIG_ALTIVEC=y
CONFIG_PREEMPT=y
CONFIG_PREEMPT_BKL=y
CONFIG_BINFMT_ELF=y
CONFIG_CMDLINE_BOOL=y
CONFIG_CMDLINE="rw init=/tools/bin/sh panic=1 PATH=/tools/bin root=/dev/hda console=ttyS0"
CONFIG_SECCOMP=y
CONFIG_ISA=y
CONFIG_ADVANCED_OPTIONS=y
CONFIG_STANDALONE=y
CONFIG_PREVENT_FIRMWARE_BUILD=y
CONFIG_BLK_DEV_LOOP=y
CONFIG_BLK_DEV_RAM=y
CONFIG_BLK_DEV_INITRD=y
CONFIG_IDE=y
CONFIG_BLK_DEV_IDE=y
CONFIG_BLK_DEV_IDECD=y
CONFIG_IDE_TASK_IOCTL=y
CONFIG_IDE_GENERIC=y
CONFIG_BLK_DEV_IDEPCI=y
CONFIG_BLK_DEV_IDEDMA_PCI=y
CONFIG_SCSI_PROC_FS=y
CONFIG_BLK_DEV_SD=y
CONFIG_SCSI_MULTI_LUN=y
CONFIG_SCSI_LOGGING=y
CONFIG_ATA=y
CONFIG_SATA_AHCI=y
CONFIG_MD=y
CONFIG_INPUT_MOUSEDEV=y
CONFIG_INPUT_MOUSEDEV_PSAUX=y
CONFIG_INPUT_KEYBOARD=y
CONFIG_INPUT_MOUSE=y
CONFIG_SERIO=y
CONFIG_VT=y
CONFIG_VT_CONSOLE=y
CONFIG_SERIAL_8250=y
CONFIG_SERIAL_8250_CONSOLE=y
CONFIG_SERIAL_8250_PCI=y
CONFIG_UNIX98_PTYS=y
CONFIG_LEGACY_PTYS=y
CONFIG_HWMON=y
CONFIG_FB=y
CONFIG_FB_MODE_HELPERS=y
CONFIG_FB_TRIDENT=y
CONFIG_FRAMEBUFFER_CONSOLE=y
CONFIG_FONTS=y
CONFIG_FONT_8x8=y
CONFIG_FONT_8x16=y
CONFIG_LOGO=y
CONFIG_LOGO_LINUX_MONO=y
CONFIG_LOGO_LINUX_VGA16=y
CONFIG_LOGO_LINUX_CLUT224=y
CONFIG_EXT2_FS=y
CONFIG_EXT3_FS=y
CONFIG_INOTIFY=y
CONFIG_INOTIFY_USER=y
CONFIG_DNOTIFY=y
CONFIG_PROC_FS=y
CONFIG_PROC_KCORE=y
CONFIG_PROC_SYSCTL=y
CONFIG_SYSFS=y
CONFIG_TMPFS=y
CONFIG_CONFIGFS_FS=y
CONFIG_SQUASHFS=y
CONFIG_PARTITION_ADVANCED=y
CONFIG_MAC_PARTITION=y
CONFIG_MSDOS_PARTITION=y
CONFIG_NLS=y
CONFIG_NLS_UTF8=y
EOF
make O=../obj/linux-$ARC-basic ARCH=$ARCHF CROSS_COMPILE=$COMPILER g5_defconfig
#make O=../obj/linux-$ARC-basic ARCH=$ARCHF CROSS_COMPILE=$COMPILER menuconfig

#make O=../obj/linux-$ARC-basic ARCH=$ARCHF CROSS_COMPILE=$COMPILER kvmconfig
make O=../obj/linux-$ARC-basic ARCH=$ARCHF CROSS_COMPILE=$COMPILER -j$(nproc)
else

make O=../obj/linux-$ARC-basic x86_64_defconfig
make O=../obj/linux-$ARC-basic kvmconfig
make O=../obj/linux-$ARC-basic -j$(nproc)
fi

}


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
    makeInitramfs
    DoQemu
    exit
    shift; shift # past argument and value
    ;;-d|-delete|-deleteall)
    delete
    shift; # past argument and value
    ;;-k|-kernel)
    KERNEL="$2"
    shift; shift;
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

if [ $ARCH == "ppc" ]; then #this is to have a full arch name, but working functions
    ARCHF="powerpc"
else
    ARCHF=$ARCH
fi

if [ -f $TOP/obj/initramfs-busybox-$ARC.cpio.gz ]; then
    if [ ! -f $TOP/obj/linux-$ARC-basic/arch/$ARCHF/boot/bzImage ]; then
        makeKernel
    fi
    DoQemu
    exit
else
    if [ -f $TOP/obj/busybox-$ARC/busybox ]; then
        makeInitramfs
        if [ ! -f $TOP/obj/linux-$ARC-basic/arch/$ARCHF/boot/bzImage ]; then
            makeKernel
        fi
        DoQemu
        exit
    else
        buildBusyBox
        makeInitramfs
        if [ ! -f $TOP/obj/linux-$ARC-basic/arch/$ARCHF/boot/bzImage ]; then
            makeKernel
        fi
        DoQemu
        exit
        fi
    fi
    
fi

