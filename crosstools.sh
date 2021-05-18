#!/bin/bash 
TARGET="powerpc64-linux-gnueabi" #default powerpc64-linux
ARCH="powerpc"
TOPC="$HOME/Projects/Emulation/Linux/crosstools"
CROSS="$TOPC/bin"
PREFIX="$TOPC/opt/cross"
PATH="$PREFIX/bin:$PATH"
CORES=$(nproc)  #replace with 1 if multicore fails

BINUTIL="2.31.1"
GCC="8.2.0"
KERNEL="5.10.2"
MUSL="1.2.1"


#Download all the files
#----------------------------------------------------------------------
function Download {
echo "[ Creating folders ]"
#first stuff happening here.
mkdir -v ${TOPC}/sources
cd $TOPC
echo "[ Download ]"
wget -c http://ftpmirror.gnu.org/binutils/binutils-$BINUTIL.tar.gz -P ${TOPC}/sources
wget -c http://ftpmirror.gnu.org/gcc/gcc-$GCC/gcc-$GCC.tar.gz -P ${TOPC}/sources
wget -c https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$KERNEL.tar.xz -P ${TOPC}/sources
wget -c https://musl.libc.org/releases/musl-$MUSL.tar.gz -P ${TOPC}/sources
}

#----------------------------------------------------------------------
function Binutils {
echo "[ Binutils ]"
echo "  [ Extracting ]"
pv ${TOPC}/sources/binutils-$BINUTIL.tar.gz | tar xzf - -C ${TOPC}/sources
cd ${TOPC}/sources/binutils-$BINUTIL/
echo "  [ Configuring ]"
mkdir build
cd build
echo $PWD
../configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
echo "  [ Compiling ]"
make -j$CORES
echo "  [ Installing ]"
make install
echo "  [ Cleaning ]"
cd ${TOPC}/sources/
rm -rf binutils-$BINUTIL/
}

#----------------------------------------------------------------------

function GCC {
echo "[ GCC ]"
echo "  [ Extracting ]"
pv ${TOPC}/sources/gcc-$GCC.tar.gz | tar xzf - -C ${TOPC}/sources
cd ${TOPC}/sources/gcc-$GCC/


# The $PREFIX/bin dir _must_ be in the PATH. We did that above.
which -- $TARGET-as || echo $TARGET-as is not in the PATH
echo "  [ Configuring ]"
mkdir build
cd build
echo $PWD

../configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers
echo "  [ Compiling ]"
make all-gcc -j$CORES
#make all-target-libgcc -j$CORES

echo "  [ Installing ]"
make install-gcc
#make install-target-libgcc

echo "  [ Cleaning ]"
cd ${TOPC}/sources/
rm -rf gcc-$GCC/
}
#----------------------------------------------------------------------

function LinuxHeaders {
echo "[ Linux Headers ]"
echo "  [ Extracting ]"
pv ${TOPC}/sources/linux-$KERNEL.tar.xz | tar xJf - -C ${TOPC}/sources
cd ${TOPC}/sources/linux-$KERNEL/


echo "  [ Make proper ]"
make mrproper

echo "  [ Installing ]"
make ARCH=${ARCH} headers_check
make ARCH=${ARCH} INSTALL_HDR_PATH=${TOPC} headers_install

echo "  [ Cleaning ]"
cd ${TOPC}/sources/
rm -rf linux-$KERNEL/
}
#----------------------------------------------------------------------

function Musl {
echo "[ Musl ]"
echo "  [ Extracting ]"
pv ${TOPC}/sources/musl-$MUSL.tar.gz | tar xzf - -C ${TOPC}/sources
cd ${TOPC}/sources/musl-$MUSL/

echo "  [ configure ]"
echo "  [ Make ]"
echo "  [ Install ]"

echo "  [ Cleaning ]"
cd ${TOPC}/sources/
rm -rf linux-$KERNEL/
}

#----------------------------------------------------------------------
function Test {
echo "[ Test ]"
${PREFIX}/bin/$TARGET-gcc --version

cd ${TOPC}
cat << EOF> "${TOPC}"/hello.c
#include <stdio.h>
int main()
{
	printf("Hello world!\n");
	return 0;	
}
EOF

${PREFIX}/bin/$TARGET-gcc -g -o hello ${TOPC}/hello.c -static -L${TOPC} -I${TOPC}
#rm ${TOPC}/hello.c
}
#----------------------------------------------------------------------
function delete {
cd ${TOPC}
rm -rf opt/
echo "Removed all files except the sources directory"
exit 1
}

#----------------------------------------------------------------------
#process commandline arguments
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -d|-delete|-deleteall)
    delete
    shift; # past argument and value
    ;;-t|-test)
    Test 
    exit 1
    shift;
    ;;-musl )
    Download
    Musl 
    exit 1
    shift;
    ;;
esac
done

Download
Binutils
GCC
LinuxHeaders
Musl
Test
