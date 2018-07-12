#!/bin/bash 
function DoQemu {
cd $TOP
qemu-system-x86_64 \
    -kernel obj/linux-x86-basic/arch/x86_64/boot/bzImage \
    -initrd obj/initramfs-busybox-x86.cpio.gz \
    -nographic -append "console=ttyS0" -enable-kvm
}

function delete {
cd $TOP
rm -rf *
exit
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
rm -rf busybox-1.29.0/
tar xjf busybox-1.29.0.tar.bz2
rm -rf obj/busybox-x86
cd $TOP/busybox-1.29.0
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
rm -rf linux-4.17.6/
rm -rf obj/linux-x86-basic
tar xJf linux-4.17.6.tar.xz
#Make our Kernel
cd $TOP/linux-4.17.6
make O=../obj/linux-x86-basic x86_64_defconfig
make O=../obj/linux-x86-basic kvmconfig
make O=../obj/linux-x86-basic -j$(nproc)
}


TOP=$HOME/Linux/teeny-linux
mkdir $TOP
cd $TOP


while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -d|-delete|-deleteall)
    delete
    shift; shift # past argument and value
    ;;-init|-makeInit|-makeinit)
    makeInitramfs
    DoQemu
    exit
    shift; shift # past argument and value
    ;;
    
esac
done

#Download if nececairy, clean an unclean build
if [ ! -f $TOP/linux-4.17.6.tar.xz ]; then
    wget -c https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.17.6.tar.xz
fi
if [ ! -f $TOP/busybox-1.29.0.tar.bz2 ]; then
    wget -c https://busybox.net/downloads/busybox-1.29.0.tar.bz2
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

