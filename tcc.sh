#!/bin/sh
rm -rf tcc-0.9.27/
wget -c https://musl.cc/x86_64-linux-musl-native.tgz
tar -xvf x86_64-linux-musl-native.tgz
cp -r x86_64-linux-musl-native/lib build/lib
cp -r x86_64-linux-musl-native/include build/include

cd /home/codeasm/Projects/Emulation/Linux/bin/linux-5.8.4/
make headers_install INSTALL_HDR_PATH=/home/codeasm/projects/Emulation/Linux/bin/build
cd ..

wget -c https://download.savannah.gnu.org/releases/tinycc/tcc-0.9.27.tar.bz2
tar -xvf tcc-0.9.27.tar.bz2
cd tcc-0.9.27/
./configure --enable-static --config-musl --cc=musl-gcc --prefix=/usr
make CC="musl-gcc -static" -j8
make test
make install DESTDIR=/home/codeasm/Projects/Emulation/Linux/bin/build


# make headers_install INSTALL_HDR_PATH=/home/codeasm/projects/Emulation/Linux/bin/build 
#DESTDIR=
