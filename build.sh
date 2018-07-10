#!/bin/bash 
function DoQemu {
cd $TOP
qemu-system-x86_64 \
    -kernel obj/linux-x86-basic/arch/x86_64/boot/bzImage \
    -initrd obj/initramfs-busybox-x86.cpio.gz \
    -nographic -append "console=ttyS0" -enable-kvm
}

function writeInit {
cat <<EOF> init
#!/bin/sh
 
mount -t proc none /proc
mount -t sysfs none /sys
 
echo -e "\nBoot took $(cut -d' ' -f1 /proc/uptime) seconds"
echo -e "\nPress Ctrl+A C to enter qemu monitor and then type quit. \n"
 
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
rm -rf linux-4.17.5/
rm -rf obj/linux-x86-basic
tar xJf linux-4.17.5.tar.xz
#Make our Kernel
cd $TOP/linux-4.17.5
make O=../obj/linux-x86-basic x86_64_defconfig
make O=../obj/linux-x86-basic kvmconfig
make O=../obj/linux-x86-basic -j$(nproc)
}


TOP=$HOME/Linux/teeny-linux
mkdir $TOP
cd $TOP

#Download if nececairy, clean an unclean build
if [ ! -f $TOP/linux-4.17.5.tar.xz ] 
    wget -c https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.17.5.tar.xz
if [ ! -f $TOP/busybox-1.29.0.tar.bz2 ] 
    wget -c https://busybox.net/downloads/busybox-1.29.0.tar.bz2

if [ -f obj/linux-x86-basic/arch/x86_64/boot/bzImage ] && [ -f $TOP/obj/initramfs-busybox-x86.cpio.gz ]; then
    DoQemu
    exit
else
    if [ -f $TOP/obj/initramfs-busybox-x86.cpio.gz ]; then
    makeKernel
    DoQemu
    exit
    else
        if [ -f $TOP/obj/busybox-x86/busybox ]; then
        makeInitramfs
        makeKernel
        DoQemu
        exit
        else
        buildBusyBox
        makeInitramfs
        makeKernel
        DoQemu
        exit
        fi
    fi
    
fi

