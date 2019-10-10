# Teeny Linux
Based on Mitch Galgs instructions on how to build a Linux kernel for qemu.
This awesome guy also updated his buildinstructions so expect some updates on my attempt if he updates too.

http://mgalgs.github.io/2015/05/16/how-to-build-a-custom-linux-kernel-for-qemu-2015-edition.html

![teenylinux booting Screenshot](https://raw.githubusercontent.com/codeasm/teeny-linux/master/resources/Screenshot.png)


My goals in non particular order are: 
* Run Linux on any/most CPU (that qemu offers, and that intrests me ;) ).
* Crosscompile Linux (probably x86_64 as a base).
* Have Firewire terminal on PowerPC. (this is part of another project)
* Compile and run Programs from within builded system
* Have small amount of scripts that can build and partialy test various goals
* network support, get a update system working
* boot from media instead of direct kernel

Most of my research and/or playing is done on a x86_64 Arch Linux system, I asume the reader is skilled enough to translate any commands or hints to their own system or reading other resources to accomplish their own goals.
This is never ment for production or replacing LFS for example. 

I do not recommend this documentation or scripts as a learning tool or seen as fact. this is just me playing arround.

# news
Updated to the latest I know Kernel and applications
* Linux Kernel  5.3.5   2019-10-07 
* BusyBox       1.31.0  2019-07-10
* beta tools script, based on LFS.

4.19.66 still works without altering the scipts

Powerpc still fails, no other arch beside x86_64 work.
see crosstools.sh for a ARM attempt, currently boots the kernel, and no busybox or temp init.

# options
The build scribt knows the following commands passable as arguments:
```bash
./build.sh -d
./build.sh -delete
./build.sh -deleteall
```
deletes all but the tarbal files (handy to restart building without downloading the tarbals

```bash
./build.sh -arch [ppc|x86_64]
./build.sh -cpu [ppc|x86_64]
```
builds for the selected arch, x86_64 is default tho, x86 isnt tested(yet)

```bash
./build.sh -init
./build.sh -makeInit
./build.sh -makeinit
```
Builds or rebuilds only the initramfs and then tries to run qemu, handy when trying new init programs or 
other initramfs tests
```bash
./build.sh -k <kernel version>
./build.sh-kernel
```

# building
run the buildscript :D

__select arch support comming__ this feature is being worked on. I want 1 scritp to do all,
altho I might consider building the crosstools externaly. so you might need to run that first.

A temporarely ARM target inside crosstools is in the work. requires arm-none-eabi- set of build tools as well as a 
fake init static compiled

# Adding new programs
TobeDone
for now Im working on the tool scibt that will build a gcc compiler to be included with the builded kernel.
when making a crosscompiled system, the tools should be native to the target.

# cross compiling

![Crosscompiled kernel on ARM Screenshot](https://raw.githubusercontent.com/codeasm/teeny-linux/master/resources/Screenshot2.png)

as seen in picture, my static linked init dint get compiled against 5.0.5 kernel headers but to 3.2.0, ill fix that someday maybe
_this is work in progress_
To do crosscompiling ive made a script called "crosstools.sh" that will add crosscompile tools if you dont have any.
From here on the variable arch can be set to the arch you made crostools for.

crosscompile.sh will build a arm based kernel and tries to boot it using qemu, for succesfull compiling, requires:
arm-none-eabi- series.

```bash
./crosscompile.sh
```
or to delete the compile attempt (without removing large downloaded files)
```bash
./crosscompile.sh -d
```

# How to build Powerpc crosstools on Arch

needed GPG keys for linux, patch and glibc headers:
79BE3E4300411886
38DBBDC86092693E
16792B4EA25340F8
gpg --keyserver hkps://pgp.mit.edu --recv-keys 79BE3E4300411886 38DBBDC86092693E 16792B4EA25340F8


These tools are 32bit, and for Powerpc G5 we need 64bits.
And browsing the Arch forums... yeah, general public intrests.... they go with the dodo.
Lets make our own Distro, with Doom and Anime... I mean documentries on space and sciense.
## 64bit
## powerpc64-linux-gnu-binutils

```
git clone https://aur.archlinux.org/powerpc64-linux-gnu-binutils.git
cd powerpc64-linux-gnu-binutils/
makepkg -si
cd ..
```

## 32bit
### powerpc-linux-gnu-binutils
```
git clone https://aur.archlinux.org/powerpc-linux-gnu-binutils.git
cd powerpc-linux-gnu-binutils/
makepkg -si
cd ..
```
### powerpc-linux-gnu-linux-api-headers
```
git clone https://aur.archlinux.org/powerpc-linux-gnu-linux-api-headers.git
cd powerpc-linux-gnu-linux-api-headers/
makepkg -si
cd ..
```
### powerpc-linux-gnu-gcc-stage1
```
git clone https://aur.archlinux.org/powerpc-linux-gnu-gcc-stage1.git
cd powerpc-linux-gnu-gcc-stage1/
makepkg -si
cd ..
```
### powerpc-linux-gnu-glibc-headers
```
git clone https://aur.archlinux.org/powerpc-linux-gnu-glibc-headers.git
cd powerpc-linux-gnu-glibc-headers/
makepkg -si
cd ..
```
### powerpc-linux-gnu-gcc-stage2
```
git clone https://aur.archlinux.org/powerpc-linux-gnu-gcc-stage2.git
cd powerpc-linux-gnu-gcc-stage2/
makepkg -si
cd ..
```
### powerpc-linux-gnu-glibc
```
git clone https://aur.archlinux.org/powerpc-linux-gnu-glibc.git
cd powerpc-linux-gnu-glibc/
makepkg -si
cd ..
```
### powerpc-linux-gnu-gcc
```
git clone https://aur.archlinux.org/powerpc-linux-gnu-gcc.git
cd powerpc-linux-gnu-gcc/
makepkg -si
cd ..
```
### Testing the compiler
Write a file containing:
-------------------------
```c
#include<stdio.h>

int main () {
        printf("Hello PowerPC!\n");
        return 0;
}
```
-------------------------
```powerpc-linux-gnu-gcc -static -g hello.cpp -o hello 
qemu-ppc hello
```

## Building bare kernel
_this is work in progress_
```
git clone https://github.com/raspberrypi/linux raspberrypi-linux
cd raspberrypi-linux
cp arch/arm/configs/bcmrpi_cutdown_defconfig .config
make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabi- oldconfig
make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabi- menuconfig
make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabi- -k
```
or do some defconfig for ppc
```
make -j 4 [u|z]Image dtbs modules
make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi-
```
```bash
export ARCH:=arm
export CROSS_COMPILE:=arm-none-linux-gnueabi-


ARCH=arm
COMPILER=arm-none-linux-gnueabi
obj-m := Hello.o
KERNELDIR := /home/ravi/workspace/hawk/linux-omapl1
PWD := $(shell pwd)
default:
    $(MAKE) -C $(KERNELDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(COMPILER) modules

clean:
    $(MAKE) -C $(KERNELDIR) M=$(PWD) ARCH=$(ARCH) clean
    
    
ARCH := arm
CROSS_COMPILE := arm-none-linux-gnueabi-
obj-m := Hello.o
KDIR := /home/ravi/workspace/hawk/linux-omapl1
PWD := $(shell pwd)
export
default:
          $(MAKE) -C $(KDIR) M=$(PWD) modules
clean:
          $(MAKE) -C $(KDIR) M=$(PWD) clean
```          
a device tree database is required for proper functioning arm targets, for my example ive used versatile-pb.dtb that is also provided after compiling the kernel.
          
          
# Resources
<https://gts3.org/2017/cross-kernel.html>
<https://balau82.wordpress.com/2010/02/28/hello-world-for-bare-metal-arm-using-qemu/>
<https://github.com/netbeast/docs/wiki/Cross-compile-test-application>
<https://www.computerhope.com/unix/ucpio.htm>
<https://unix.stackexchange.com/questions/56614/send-file-by-xmodem-or-kermit-protocol-with-gnu-screen/65362#65362>
<https://balau82.wordpress.com/2010/03/22/compiling-linux-kernel-for-qemu-arm-emulator/>
<https://designprincipia.com/compile-linux-kernel-for-arm-and-run-on-qemu/>
