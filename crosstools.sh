#!/bin/bash 
TARGET="arm-linux-gnueabihf"
ARCH="arm"
TOPC="$HOME/emulation/linux/crosstools"
CROSS="$TOPC/bin"
PREFIX="$TOPC/opt/cross"
PATH="$PREFIX/bin:$PATH"
CORES=$(nproc)  #replace with 1 if multicore fails
CLIB=

BINUTIL="2.36.1"
GCC="11.1.0"
KERNEL="5.12.5"
MUSL="1.2.1"
NEWLIB="4.1.0"


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
if [ "$MUSLDO" = true ]; then
    wget -c https://musl.libc.org/releases/musl-$MUSL.tar.gz -P ${TOPC}/sources
else
    wget -c https://sourceware.org/pub/newlib/newlib-$NEWLIB.tar.gz -P ${TOPC}/sources
fi
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
../configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror --enable-shared --enable-64-bit-bfd
echo "  [ Compiling ]"
make all -j$CORES
echo "  [ Installing ]"
make install
echo "  [ Cleaning ]"
cd ${TOPC}/sources/
rm -rf binutils-$BINUTIL/
}

#----------------------------------------------------------------------

function GCC_step1 {
echo "[ GCC ]"
echo "  [ Extracting ]"
pv ${TOPC}/sources/gcc-$GCC.tar.gz | tar xzf - -C ${TOPC}/sources
cd ${TOPC}/sources/gcc-$GCC/


# The $PREFIX/bin dir _must_ be in the PATH. We did that above.
which -- $TARGET-as || echo $TARGET-as is not in the PATH exit 1
echo "  [ Configuring ]"
mkdir build
cd build
echo $PWD

if [ "$MUSLDO" = true  ]; then
 #   Musl
 ../configure --target=$TARGET --prefix="$PREFIX" --disable-nls \
             --enable-languages=c,c++ \
             --without-headers  \
             --with-gnu-as --with-gnu-ld
else
#newlib
../configure --target=$TARGET --prefix="$PREFIX" \
             --without-headers --with-newlib \
             --with-gnu-as --with-gnu-ld
fi

echo "  [ Compiling ]"
make all-gcc -j$CORES

echo "  [ Installing ]"
make install-gcc
#make install-target-libgcc

echo "  [ Cleaning ]"
#cd ${TOPC}/sources/
#rm -rf gcc-$GCC/
}
#----------------------------------------------------------------------

function GCC_step2 {
echo "[ GCC step 2]"
cd ${TOPC}/sources/gcc-$GCC/

echo "  [ Compiling second time ]"
cd build
echo $PWD

../configure --target=$TARGET --prefix=$PREFIX \
                --with-newlib --with-gnu-as --with-gnu-ld \
                --disable-shared --disable-libssp

echo "  [ Compiling ]"
make all -j$CORES

echo "  [ Installing ]"
make install
#make install-target-libgcc

echo "  [ Cleaning ]"
#cd ${TOPC}/sources/
#rm -rf gcc-$GCC/
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
./configure --prefix=$PREFIX --target=$TARGET 
echo "  [ Make ]"
make
echo "  [ Install ]"
make install
echo "  [ Cleaning ]"
cd ${TOPC}/sources/
rm -rf musl-$MUSL/
}

#----------------------------------------------------------------------

function Newlib {
echo "[ Newlib ]"
echo "  [ Extracting ]"
pv ${TOPC}/sources/newlib-$NEWLIB.tar.gz | tar xzf - -C ${TOPC}/sources
cd ${TOPC}/sources/newlib-$NEWLIB/

echo "  [ configure ]"
#rm -rf build
mkdir build
cd build
../configure --target=$TARGET --prefix=$PREFIX
echo "  [ Make ]"
make all
echo "  [ Install ]"
make install
echo "  [ Cleaning ]"
cd ${TOPC}/sources/
rm -rf linux-$KERNEL/
}

#----------------------------------------------------------------------
function Test {
echo "[ Test ]"
${PREFIX}/bin/$TARGET-gcc --version

cd ${TOPC}
cat << EOF > "${TOPC}"/hello.c
#include <stdio.h>
int main()
{
	printf("Hello world!\n");
	return 0;	
}
EOF

${PREFIX}/bin/$TARGET-gcc -v
${PREFIX}/bin/$TARGET-gcc -g -o hello ${TOPC}/hello.c -static -L${TOPC}/include -I${TOPC}/include
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
    ;;-glibc|-c)
    CLIB=glibc
    shift; # past argument and valu
    ;;-musl|-m)
    CLIB=musl
    MUSLDO=true
    shift; # past argument and valu
esac
done

#Download
#Binutils
#GCC_step1
#LinuxHeaders


case $CLIB in
    newlib)
#        Newlib
        ;;
    musl)
        Musl
        ;;
    glibc)
#        Glibc
        ;;
    libc)
#        Libc
        ;;
    picolibc)
#        Picolibc
        ;;
    *)
        echo "no libc set or chosen" 
        exit 1
        ;;
esac
#GCC_step2
Test
