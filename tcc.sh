#!/bin/sh
TARGET=$HOME/Projects/Emulation/Linux/bin/build    
                                 #location for the build, change this for your location
                               
# a bunch of helpfull functions
#----------------------------------------------------------------------
./musl.sh
## The Linux headers might be needed for tcc
cd /home/codeasm/Projects/Emulation/Linux/bin/linux-5.8.4/
#make headers_install INSTALL_HDR_PATH=$TARGET
cd ..

rm -rf tcc-0.9.27/

#wget -c https://download.savannah.gnu.org/releases/tinycc/tcc-0.9.27.tar.bz2
#tar -xvf tcc-0.9.27.tar.bz2
#cd tcc-0.9.27/
#./configure --enable-static --config-musl --cc=musl-gcc --prefix=/usr
#make CC="musl-gcc -static" -j8
#make test
#make install DESTDIR=$TARGET

#wget -c https://ftp.gnu.org/gnu/make/make-4.3.tar.gz
#tar -xvf make-4.3.tar.gz
#cd make-4.3
#CC="musl-gcc -static" ./configure --prefix=/usr --without-guile && make
#make install DESTDIR=$TARGET
#cd ..

# make headers_install INSTALL_HDR_PATH=/home/codeasm/projects/Emulation/Linux/bin/build 
#DESTDIR=
