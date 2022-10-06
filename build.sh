#!/bin/sh
. ./vars.sh
. ./ReqCheck.sh

#DO NOT EDIT BELOW it should not be necessary.
#-----------------------------------------------------------
MAKEINIT=false                  #we dont want to overdo a makeinit, used internaly
MODULE=false                    #add modules to linux (asuming kernel already supports this)

#first stuff happening here.
mkdir -p $TOP
cd $TOP

#a bunch of helpfull functions
#----------------------------------------------------------------------
function DoQemu() {
cd $TOP
qemu-system-$ARCH \
    -m $RAM \
    -kernel obj/linux-$ARC/arch/$ARCH/boot/bzImage \
    -initrd obj/initramfs-busybox-$ARC.cpio.gz \
    -nographic -append "console=ttyS0" $NET $OPTION
}

#----------------------------------------------------------------------
function delete() {
cd $TOP
mv linux-$KERNEL.tar.$KTYPE ../
mv busybox-$BUSY.tar.bz2 ../
rm -rf *
mv ../linux-$KERNEL.tar.$KTYPE linux-$KERNEL.tar.$KTYPE
mv ../busybox-$BUSY.tar.bz2 busybox-$BUSY.tar.bz2
exit 0
}

#----------------------------------------------------------------------
function writeInit() {
cat << EOF > init 
#!/bin/sh
syslogd 
mount -t devtmpfs devtmpfs /dev
mkdir /dev/pts
mount -t devpts devpts /dev/pts
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
while [ 1 ]; do
    /usr/bin/setsid /bin/cttyhack $LOGINREQUIRED
done
EOF
}

#----------------------------------------------------------------------
function copytoimage() {      #This function will copy nececairy files into the initramfs

# modules option
if $MODULE ; then
    mkdir -pv lib/modules/$KERNEL/extra
    cp $MODULEURL/hello.ko lib/modules/$KERNEL/extra/hello.ko
fi

# the extra builded files to be included into the initramfs
if [ -d $TOP/build/ ]; then
    #add packages (non overwrite, add)
    cat $TOP/build/var/lib/dpkg/status >> $TOP/initramfs/$ARC-busybox/var/lib/dpkg/status
    mv $TOP/build/var/lib/dpkg/status $TOP/status
    #copy files, overwrite if nececairy
    cp -r $TOP/build/. $TOP/initramfs/$ARC-busybox/
    #restore build dir
    mv  $TOP/status $TOP/build/var/lib/dpkg/status
fi

#add user?
cat << EOF > $TOP/initramfs/$ARC-busybox/etc/passwd
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

make O=../obj/busybox-$ARC defconfig $COMPILER

# do a static lib thing for busy, 
sed -i '/# CONFIG_STATIC is not set/c\CONFIG_STATIC=y' ../obj/busybox-$ARC/.config
#for musl we experimentaly determined these to be nececairy


cd ../obj/busybox-$ARC
make -j$CORECOUNT $COMPILER
make install $COMPILER
}

function makeNewInitramfs() {
#Make the initramfs (first clean ofcourse)
rm -rf $TOP/initramfs
mkdir -pv $TOP/initramfs/$ARC-busybox
cd $TOP/initramfs/$ARC-busybox
mkdir -pv {bin,sbin,root,etc,proc,sys,usr/{bin,sbin,local/{bin,lib}}}
mkdir -pv {var/{run,lib/dpkg},etc/network/{if-down.d,if-up.d,if-down.d,if-post-down.d,if-post-up.d,if-pre-down.d,if-pre-up.d}}
cat << EOF > var/lib/dpkg/status
Package: busybox
Status: hold ok installed
Priority: optional
Section: base
Version: $BUSY

EOF
makeInitramfs
}

function makeInitramfs() {
cd $TOP/initramfs/$ARC-busybox
cp -av $TOP/obj/busybox-$ARC/_install/* .
#add new files to copy here?
writeInit
copytoimage
cd $TOP/initramfs/$ARC-busybox/root
cat << EOF > .profile
alias ls='ls --color=auto'
alias today='date +"%Y-%m-%d"'
alias todaytime='date +"%Y-%m-%d %H:%M"'

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin:tools

PS1='\[\033[35m\]\t\[\033[m\][\[\033[1;31m\]\u\[\033[0m\]@\[\e[1;34m\]\h\[\e[0m\]:\[\e[94m\]\w\[\e[0m\]]\\$ \[\e[m\]' 
EOF

cat << EOF > hello.c
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

function makeKernel() {
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

make mrproper
make O=../obj/linux-$ARC x86_64_defconfig
make O=../obj/linux-$ARC kvm_guest.config
sed -i 's/CONFIG_WERROR=y/# CONFIG_WERROR is not set/' ../obj/linux-x86/.config
make O=../obj/linux-$ARC -j$CORECOUNT

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
    ;;-t|-time)
    echo "Timed compilation"
    OVERALL_START="$(date +%s)"
    buildBusyBox
    INIT_START="$(date +%s)"
    makeNewInitramfs
    INIT_END="$(date +%s)"
    makeKernel
    OVERALL_END="$(date +%s)"
    echo "Busybox took: $[ ${INIT_START} - ${OVERALL_START} ] seconds to compile"
    echo "Initram took: $[ ${INIT_END} - ${INIT_START} ] seconds to build"
    echo "Kernel took: $[ ${OVERALL_END} - ${INIT_END} ] seconds to compile"
    echo "The overall code took: $[ ${OVERALL_END} - ${OVERALL_START} ] seconds to run"
    exit 0
    shift; # past argument and value
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

