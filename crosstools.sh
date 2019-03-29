#!/bin/bash
KERNEL="5.0.5"                  #Kernel release number.
ARCH="arm"                   #default arch
TOP=$HOME/Linux/$ARCH-linux     #location for the build
COMPILER="arm-none-eabi-"   #compiler pre.

mkdir -p $TOP
cd $TOP
#need :
#arm-none-eabi-gcc
#process commandline arguments
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -d|-delete)
    rm -rf linux-$KERNEL/   
    rm -rf $TOP/obj/
    exit
    shift; shift
    
    ;;
esac
done

function makeKernel {
tar xJf linux-$KERNEL.tar.xz

#Make our Kernel
cd $TOP/linux-$KERNEL

# Write out Linux kernel .config file
mkdir "${TOP}"/obj/linux-$ARCH/

make O=../obj/linux-$ARCH ARCH=$ARCH versatile_defconfig

# this compiles the kernel, add "-j <number_of_cpus>" to it to use multiple CPUs to reduce build time
make O=../obj/linux-$ARCH ARCH=$ARCH CROSS_COMPILE=$COMPILER -j$(nproc) 
}

function makeTempRootFS {

#${COMPILER}gcc -static ${TOP}/obj/init.c -o init
cd $TOP/obj
cp ../../test test
rm rootfs
echo  test | cpio -o --format=newc > rootfs

}


wget -c https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$KERNEL.tar.xz
if [ ! -f $TOP/obj/linux-$ARCH/vmlinux ]; then
    makeKernel
fi
makeTempRootFS
qemu-system-arm -M versatilepb -kernel $TOP/obj/linux-$ARCH/arch/$ARCH/boot/zImage -dtb $TOP/obj/linux-$ARCH/arch/$ARCH/boot/dts/versatile-pb.dtb -initrd $TOP/obj/rootfs -append "ignore_loglevel log_buf_len=10M print_fatal_signals=1 LOGLEVEL=8 earlyprintk=vga,keep sched_debug append root=/dev/ram rdinit=/test"
