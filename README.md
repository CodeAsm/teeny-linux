# Teeny Linux

Based on Mitch Galgs instructions on how to build a Linux kernel for qemu.
This awesome guy also updated his buildinstructions so expect some updates on my attempt if he updates too.

<http://mgalgs.github.io/2015/05/16/how-to-build-a-custom-linux-kernel-for-qemu-2015-edition.html>

![teenylinux booting Screenshot](https://raw.githubusercontent.com/codeasm/teeny-linux/main/resources/Screenshot.png)

* The kernel currently is: 8.8Mb
* The initramfs without other programs but busybox: 694K
* Added musl will grow the initramfs: 78Mb
With carefull manipulation, the kernel can be made smaller, so does initramfs

My goals in non particular order are:

* Run Linux on any/most CPU (that qemu offers, and that intrests me ;) ).
* Crosscompile Linux (probably x86_64 as a base).
  * Partial functional
* Have Firewire terminal on PowerPC. (this is part of another project)
* Have small amount of scripts that can build and partialy test various goals
* get a update system working
* smaller compiler for inside (TCC, work has started in a branch)

Most of my research and/or playing is done on a x86_64 Arch Linux system, I asume the reader is skilled enough to translate any commands or hints to their own system or reading other resources to accomplish their own goals.
This is never ment for production or replacing LFS for example.

I do not recommend this documentation or scripts as a teaching tool or seen as fact. this is just me playing arround.
You can however learn from it, or teach how not to do things.
*user root, password root*

## news

Updated to the latest I know Kernel and applications

| Package        | Version    | Date        |
| :------------- | :--------- | ----------: |
| Linux kernel   | 5.13.1     | 2021-07-07  |
| BusyBox        | 1.33.1     | 2021-05-03  |
| Drobbear       | 2020.81    | 2020-09-29  |

* Added a ReqCheck.sh to check for basic program requirements and permisions.
* extracted the user variables to vars.sh, nomore main build.sh updates too often
* beta tools script, based on LFS.
* modules support added
* added Musl option for basic gcc compilation inside envirement
  Not from sources but precompiled.
* crosscompiler support minimal
* networking works if using bridge or user

4.18.1 still works without altering the scipts

KVM config changed after Kernel 5.10, changed accordingly.
Powerpc still fails, no other arch beside x86_64 work.
see crosstools.sh for a ARM attempt, currently boots the kernel, and no busybox or temp init.
Dropbear has been added as a extra one could compile. everything inside the build directory gets included
network has been changed to reflect my current tap/bridge layout.

## options

The build script knows the following commands passable as arguments:

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

Build and start a instance with a mac adress of choice

```bash
./build.sh -net <macaddr>
```

for example

```bash
./build.sh -net 52:55:00:d1:55:01
```

Will run a VM with that specific macaddr (you need to change the ip inside or do DHCP trickery).

Ive added a user called root inside the passwd file, to login, use password root
to build without login prompt:

```bash
./build.sh -nl
```

or

```bash
./build.sh -nologin
```

this is like the old behavior.

### Modules

before any module can be compiled, a first run without support has to be done, or atleast the linux kernel source folder should be compiled. The sample module is a git submodule, and you should init this if you havent already by:

```sh

git submodule init
git submodule update

```

for more submodule details, check: [Cloning a Project with Submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules#)

Then first do a dry run build without modules:

```sh
./build

```

After building the kernel, termination of the qemu instance is posible, a simple test to see there are no mods also posible
Right after compilation, go into the modules folder, delete the old initramfs and compile a new module.
after completion, rebuild initramfs and test the installed module:

```sh
cd module
make clean
make
cd ..
./build -mod
```

alternativly this can also be used to make a new init, for instance to add other tools from the build dir.

```sh
./build -module
```

feel free to do this diferently when requirements change
currently loads a test module and supports

```sh
modprobe [module name]
lsmod
modprobe -r [module name]
```

check buildscipt where to place module or change code to load yours.
default script copies the hello.ko to /lib/module/[arch]/

## building

run the buildscript :D

__select arch support comming__ this feature is being worked on. I want 1 scritp to do all,
altho I might consider building the crosstools externaly. so you might need to run that first.

A temporarely ARM target inside crosstools is in the work. requires arm-none-eabi- set of build tools as well as a
fake init static compiled

## Adding new programs

For new programs to be added, there are multiple ways to do so. The easiest I think is to either manualy or using a script to build and copy the required files into the to be made initramfs.

Everything inside the ``$TOP/bin/build/`` will be copied over to the new initramfs.
Dropbear is an example build script that will build dropbear (an SSH server/client) staticly compiled.

### Musl

Based on Dropbear, Musl precompiled installer script has been added. More information and the tarfile can be found here: <https://musl.cc/>
Run to install:

```sh
./musl.sh
```

Dont forget to rebuild init, with for example

```sh
./build.sh -init
```

Now compilation using gcc inside the envirement should be posible. the included C source should compile succesfully to hello and display hello world using:

```sh
gcc -o hello hello.c -I /include/
./hello
```

Uninstalling, or actualy deleting. It will delete the complete /build/ contents, rerun other tools if needed to keep:

```sh
./musl.sh -d
```

## Network

To get basic network working, the current buildscipt and setup of qemu will use basic networking.
The IP will be 10.0.2.15 and you can reach the internet if your host and qemu allows other virtual machines aswell.

To use a bridge setup (wich I wanted to try anyway) and be able to ping another virtual machine do the following:
Create a bridge and 2 taps (1 tap for a virual machine, either eth0/or wireless for internet, or another tap for another virtual machine).
As root (or use sudo)

```sh
ip tuntap add tap0 mode tap
ip tuntap add tap1 mode tap
```

Create the actual bridge

```sh
brctl  addbr br0
```

Add the two taps to the bridge

```sh
brctl addif br0 tap0
brctl addif br0 tap1
```

Bring the interfaces up, so they actualy work.

```sh
ifconfig tap0 up
ifconfig tap1 up
ifconfig br0 up
```

then add a network device to your qemu instance, if using my buildscript, run the following

```sh
./build -net 52:55:00:d1:55:01
```

inside one of the qemu instances, change the static ip:

```sh
ifconfig eth0 down
ifconfig eth0 up 10.0.2.16 netmask 255.255.255.0 up
```

And now you should be able to ping eachother and do stuff. If you setup a DHCP server or add the bridge to a network with a DHCP server, you can set the instances to recieve a IP from the said DHCP server.

### Removing

To remove interfaces and shutdown stuff
delete a tap (also for tap1 or eth0) and deteling the tap

```sh
brctl delif br0 tap0
tunctl -d tap0
```

Bring the bridge down and remove it:

```sh
ifconfig br0 down
brctl delbr br0
```

Now you can up your eth0 or wirelless again for internets or use a VM without these bridges and use usermode networking.

### Extra handy network commands and links

To flush the ip and be able to add eth0 of your host to the bridge:

```sh
ip addr flush dev eth0
```

Checking out if the bridge has the right and all taps or interfaces you wanted:

```sh
brctl show
```

More details and tips can be found at:

* <https://gist.github.com/extremecoders-re/e8fd8a67a515fee0c873dcafc81d811c>
* <https://wiki.qemu.org/Documentation/Networking#Tap>
* <https://wiki.archlinux.org/index.php/Network_bridge#With_bridge-utils>

## cross compiling

![Crosscompiled kernel on ARM Screenshot](https://raw.githubusercontent.com/codeasm/teeny-linux/main/resources/Screenshot2.png)

as seen in picture, my static linked init dint get compiled against 5.0.5 kernel headers but to 3.2.0, ill fix that someday maybe
_this is work in progress_
To do crosscompiling ive made a script called "crosstools.sh" that will add crosscompile tools if you dont have any.
From here on the variable arch can be set to the arch you made crostools for.

crosscompile.sh will build a arm based kernel and tries to boot it using qemu, for succesfull compiling, requires:
arm-none-eabi- series.

```sh
./crosscompile.sh
```

or to delete the compile attempt (without removing large downloaded files)

```bash
./crosscompile.sh -d
```

## How to build Powerpc crosstools on Arch

needed GPG keys for linux, patch and glibc headers:
79BE3E4300411886
38DBBDC86092693E
16792B4EA25340F8
gpg --keyserver hkps://pgp.mit.edu --recv-keys 79BE3E4300411886 38DBBDC86092693E 16792B4EA25340F8

These tools are 32bit, and for Powerpc G5 we need 64bits.
And browsing the Arch forums... yeah, general public intrests.... they go with the dodo.
Lets make our own Distro, with Doom and Anime... I mean documentries on space and sciense.

### 64bit

### powerpc64-linux-gnu-binutils

```sh
git clone https://aur.archlinux.org/powerpc64-linux-gnu-binutils.git
cd powerpc64-linux-gnu-binutils/
makepkg -si
cd ..
```

### 32bit

### powerpc-linux-gnu-binutils

```sh
git clone https://aur.archlinux.org/powerpc-linux-gnu-binutils.git
cd powerpc-linux-gnu-binutils/
makepkg -si
cd ..
```

### powerpc-linux-gnu-linux-api-headers

```sh
git clone https://aur.archlinux.org/powerpc-linux-gnu-linux-api-headers.git
cd powerpc-linux-gnu-linux-api-headers/
makepkg -si
cd ..
```

### powerpc-linux-gnu-gcc-stage1

```sh
git clone https://aur.archlinux.org/powerpc-linux-gnu-gcc-stage1.git
cd powerpc-linux-gnu-gcc-stage1/
makepkg -si
cd ..
```

### powerpc-linux-gnu-glibc-headers

```sh
git clone https://aur.archlinux.org/powerpc-linux-gnu-glibc-headers.git
cd powerpc-linux-gnu-glibc-headers/
makepkg -si
cd ..
```

### powerpc-linux-gnu-gcc-stage2

```sh
git clone https://aur.archlinux.org/powerpc-linux-gnu-gcc-stage2.git
cd powerpc-linux-gnu-gcc-stage2/
makepkg -si
cd ..
```

### powerpc-linux-gnu-glibc

```sh
git clone https://aur.archlinux.org/powerpc-linux-gnu-glibc.git
cd powerpc-linux-gnu-glibc/
makepkg -si
cd ..
```

### powerpc-linux-gnu-gcc

```sh
git clone https://aur.archlinux.org/powerpc-linux-gnu-gcc.git
cd powerpc-linux-gnu-gcc/
makepkg -si
cd ..
```

### Testing the compiler

Write a file containing:

```c
#include<stdio.h>

int main () {
        printf("Hello PowerPC!\n");
        return 0;
}
```

```sh
powerpc-linux-gnu-gcc -static -g hello.cpp -o hello 
qemu-ppc hello
```

### Building bare kernel

_this is work in progress_.

```sh
git clone https://github.com/raspberrypi/linux raspberrypi-linux
cd raspberrypi-linux
cp arch/arm/configs/bcmrpi_cutdown_defconfig .config
make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabi- oldconfig
make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabi- menuconfig
make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabi- -k
```

or do some defconfig for ppc

```sh
make -j 4 [u|z]Image dtbs modules
make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabi-
```

```sh
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

## Resources

* <https://www.computerhope.com/unix/ucpio.htm>
* <https://unix.stackexchange.com/questions/56614/send-file-by-xmodem-or-kermit-protocol-with-gnu-screen/65362#65362>
* <https://www.lifewire.com/bash-for-loop-examples-2200575>

### Compilers

* <https://stackoverflow.com/questions/17939930/finding-out-what-the-gcc-include-path-is>

### Crosscompile

* <https://gts3.org/2017/cross-kernel.html>
* <https://balau82.wordpress.com/2010/02/28/hello-world-for-bare-metal-arm-using-qemu/>
* <https://github.com/netbeast/docs/wiki/Cross-compile-test-application>
* <https://balau82.wordpress.com/2010/03/22/compiling-linux-kernel-for-qemu-arm-emulator/>
* <https://designprincipia.com/compile-linux-kernel-for-arm-and-run-on-qemu/>
* <https://stackoverflow.com/questions/49391116/build-newlib-with-existing-cross-compiler>
* <https://wiki.osdev.org/Porting_Newlib>
* <https://github.com/john-tipper/Cross-compile-toolchain-for-linux-on-OSX/>

### For TinyC Compiler

* <https://stackoverflow.com/questions/11307465/destdir-and-prefix-of-make>
* <https://www.monperrus.net/martin/compiling-c-code-with-dietlibc-and-tcc>

### Bash tricks

* <https://linuxhandbook.com/bash-arrays/>
* <https://www.cyberciti.biz/faq/finding-bash-shell-array-length-elements/>
