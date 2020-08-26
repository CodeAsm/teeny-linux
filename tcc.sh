#!/bin/sh
rm -rf tcc-0.9.27/
wget -c https://musl.cc/x86_64-linux-musl-native.tgz
tar -xvf x86_64-linux-musl-native.tgz
wget -c https://download.savannah.gnu.org/releases/tinycc/tcc-0.9.27.tar.bz2
tar -xvf tcc-0.9.27.tar.bz2
cd tcc-0.9.27/
./configure --enable-static --config-musl --cc=musl-gcc --prefix=/
make CC="musl-gcc -static" -j8
make test
make install DESTDIR=/home/codeasm/Projects/Emulation/Linux/bin/build


# make headers_install INSTALL_HDR_PATH=/home/codeasm/projects/Emulation/Linux/bin/build 
#DESTDIR=
