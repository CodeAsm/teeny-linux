#!/bin/sh
TOP=$HOME/Projects/Emulation/Linux/bin  #location for the build, change this for your location

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


cd $TOP
mkdir iso
cd iso
mkdir boot
cd boot
mkdir grub
cd grub
cat << EOF> grub.cfg 

set menu_color_normal=white/black
set menu_color_highlight=light-blue/black

menuentry "TeenyLinux" {
	set gfxpayload=keep
	linux	/boot/vmlinuz console=tty0 
	initrd	/boot/initramfs.cpio.gz
}

menuentry "TeenyLinux Serial" {
	linux	/boot/vmlinuz console=ttyS0 
	initrd	/boot/initramfs.cpio.gz
}
EOF
cd $TOP
cp obj/linux-x86/arch/x86_64/boot/bzImage iso/boot/vmlinuz
cp obj/initramfs-busybox-x86.cpio.gz iso/boot/initramfs.cpio.gz
grub-mkrescue --xorriso=/bin/xorriso -o boot.iso iso/ 
qemu-system-x86_64 -cdrom boot.iso
