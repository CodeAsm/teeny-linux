#!/bin/bash 
TARGET="powerpc64-linux" #default
ARCH="powerpc"
TOPC="$HOME/Linux/crosstools"
CROSS="$TOPC/bin"

BINUTIL="2.31.1"
KERNEL="4.17.14" #lower than 3x, change the path !
GCC="8.2.0"
GLIBC="2.28"
MPFR="4.0.1" 
GMP="6.1.2"
MPC="1.0.3"
ISL="0.20"
CLOOG="0.18.4" # CLFS uses .2



#first stuff happening here.
mkdir -v ${TOPC}/sources
cd $TOPC

wget -c http://ftpmirror.gnu.org/binutils/binutils-$BINUTIL.tar.gz -P ${TOPC}/sources
wget -c http://ftpmirror.gnu.org/gcc/gcc-$GCC/gcc-$GCC.tar.gz -P ${TOPC}/sources
wget -c https://www.kernel.org/pub/linux/kernel/v4.x/linux-$KERNEL.tar.xz -P ${TOPC}/sources
wget -c http://ftpmirror.gnu.org/glibc/glibc-$GLIBC.tar.xz -P ${TOPC}/sources
wget -c http://ftpmirror.gnu.org/mpfr/mpfr-$MPFR.tar.xz -P ${TOPC}/sources
wget -c http://ftpmirror.gnu.org/gmp/gmp-$GMP.tar.xz -P ${TOPC}/sources
wget -c http://ftpmirror.gnu.org/mpc/mpc-$MPC.tar.gz -P ${TOPC}/sources
wget -c http://isl.gforge.inria.fr/isl-$ISL.tar.xz -P ${TOPC}/sources
wget -c https://www.bastoul.net/cloog/pages/download/cloog-$CLOOG.tar.gz -P ${TOPC}/sources

for f in *.tar*; do tar xf $f; done

cd gcc-$GCC
ln -s ../mpfr-$MPFR mpfr
ln -s ../gmp-$GMP gmp
ln -s ../mpc-$MPC mpc
ln -s ../isl-$ISL isl
ln -s ../cloog-$CLOOG cloog
cd ..

sudo mkdir -p $CROSS
sudo chown $USER $CROSS

export PATH=$CROSS:$PATH

#binutil
#rm -rf build-binutils # save for rebuilds
#mkdir build-binutils
#cd build-binutils
#../binutils-$BINUTIL/configure --prefix=$CROSS --target=$TARGET --disable-multilib --disable-nls
#make -j$(nproc) #CFLAGS='-Wno-implicit-fallthrough' #added weird new gcc error I dont care bout
#make install
#cd ..

#linux headers
#cd linux-$KERNEL
#make ARCH=$ARCH INSTALL_HDR_PATH=$CROSS/$ARCH-linux headers_install
#cd ..

#gcc compilers

# The $PREFIX/bin dir _must_ be in the PATH. We did that above.
which -- $TARGET-as || echo $TARGET-as is not in the PATH

rm -rf build-gcc #just save for rebuilds
mkdir -p build-gcc
cd build-gcc
../gcc-$GCC/configure --prefix=$CROSS --target=$TARGET --enable-languages=c,c++ --disable-multilib CFLAGS=-mlong-double-128 --without-headers --disable-nls
make -j$(nproc) all-gcc
make all-target-libgcc
make install-gcc
make install-target-libgcc
cd ..

#standard libs and joy
#rm -rf build-glibc #saver for rebuilds
#mkdir -p build-glibc
#cd build-glibc
#../glibc-$GLIBC/configure --prefix=$CROSS/$TARGET --build=$MACHTYPE --host=$TARGET --target=$TARGET --with-headers=$CROSS/$TARGET/include --disable-multilib  #libc_cv_forced_unwind=yes
#make install-bootstrap-headers=yes install-headers
#make -j4 csu/subdir_lib
#install csu/crt1.o csu/crti.o csu/crtn.o $CROSS/$TARGET/lib
#$TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $CROSS/$TARGET/lib/libc.so
#touch $CROSS/$TARGET/include/gnu/stubs.h
#cd ..

#compiler support
#standard C
