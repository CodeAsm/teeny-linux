#!/bin/sh
wget -c https://musl.cc/x86_64-linux-musl-native.tgz
tar -xvf x86_64-linux-musl-native.tgz
#cp -r x86_64-linux-musl-native/. build/


# the following is a result of me trying to get TCC to compile and work
# TCC compiles, staticly and runs... but I yet have to figure out how to run
# TCC with crt and stdio.h working (I can get it to print its missing printf.h :P

## Only these files dint seem to work
#cp -r x86_64-linux-musl-native/lib/crti.o build/lib/crti.o
#cp -r x86_64-linux-musl-native/lib/crt1.o build/lib/crt1.o
#cp -r x86_64-linux-musl-native/lib/crtn.o build/lib/crtn.o

## These folders are needed?
cp -r x86_64-linux-musl-native/lib build
cp -r x86_64-linux-musl-native/include build

## The Linux headers might be needed for tcc
cd /home/codeasm/Projects/Emulation/Linux/bin/linux-5.8.4/
make headers_install INSTALL_HDR_PATH=/home/codeasm/projects/Emulation/Linux/bin/build
cd ..

rm -rf tcc-0.9.27/

wget -c https://download.savannah.gnu.org/releases/tinycc/tcc-0.9.27.tar.bz2
tar -xvf tcc-0.9.27.tar.bz2
cd tcc-0.9.27/
./configure --enable-static --config-musl --cc=musl-gcc --prefix=/usr
make CC="musl-gcc -static" -j8
make test
make install DESTDIR=/home/codeasm/Projects/Emulation/Linux/bin/build


# make headers_install INSTALL_HDR_PATH=/home/codeasm/projects/Emulation/Linux/bin/build 
#DESTDIR=
