#!/bin/sh
. ./vars.sh
. ./ReqCheck.sh

## The following worked almost, just I dint use the right format for this
#while read line; do
#    [[ $line =~ KERNEL= ]] && declare "$line" && break
#done < ./build.sh  

cd $TOP

#First some sanity checks -------------------------------------------------
if ! command -v grub-mkrescue &> /dev/null
then
    echo "grub-mkrescue could not be found"
    exit
fi

if ! command -v /bin/xorriso &> /dev/null
then
    echo "/bin/xorriso could not be found"
    exit
fi

if [ ! -f $TOP/obj/initramfs-busybox-$ARC.cpio.gz ]; then
    echo "initramfs could not be found, run build first!"
    exit
fi

    if [ ! -f $TOP/obj/linux-$ARC/arch/$ARC/boot/bzImage ]; then
    echo "Linux kernel could not be found, run build first!"
    exit
fi

# Everything seems to be in place, lets rock and roll baby -----------------
mkdir iso
cd iso
mkdir boot
cd boot
mkdir grub
cd grub
cat << EOF> grub.cfg 

set menu_color_normal=white/black
set menu_color_highlight=light-blue/black

menuentry "TeenyLinux $KERNEL" {
	set gfxpayload=keep
	linux	/boot/vmlinuz console=tty0 
	initrd	/boot/initramfs.cpio.gz
}

menuentry "TeenyLinux $KERNEL Serial" {
	linux	/boot/vmlinuz console=ttyS0 
	initrd	/boot/initramfs.cpio.gz
}
EOF
cd $TOP
cp obj/linux-x86/arch/x86/boot/bzImage iso/boot/vmlinuz
cp obj/initramfs-busybox-x86.cpio.gz iso/boot/initramfs.cpio.gz
grub-mkrescue --xorriso=/bin/xorriso -o boot.iso iso/ 
qemu-system-x86_64 -cdrom boot.iso -m 2G
