#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later

. ./vars.sh
. ./ReqCheck.sh

ARCHF=$ARCH

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
	if [ $ARCH == "i686" ]; then
		ARCHF="i386"	# not arch full, but what the actual kernel folder is called
						# when compiling for pentium3
	fi
	#echo "Using kernel folder: $ARCHF"
    if [ ! -f "$TOP/obj/linux-$ARC/arch/${ARCHF}/boot/bzImage" ]; then
        echo "Error: bzImage not found in $TOP/obj/linux-$ARC/arch/${ARCHF}/boot/"
        exit 1
    fi

# Everything seems to be in place, lets rock and roll baby -----------------
rm -rf iso # recreate iso folder
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
cp obj/linux-$ARC/arch/${ARCHF}/boot/bzImage iso/boot/vmlinuz
cp obj/initramfs-busybox-$ARC.cpio.gz iso/boot/initramfs.cpio.gz
grub-mkrescue --xorriso=/bin/xorriso -o boot-$ARCH.iso iso/ 
if [ "$ARCH" == "i686" ]; then
	Q_ARCH="i386"
else
	Q_ARCH="$ARCH"
fi
qemu-system-$Q_ARCH -cdrom boot-$ARCH.iso -m 2G
