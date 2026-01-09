#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later

set -e

TARGET="arm-linux-gnueabihf"
ARCH="arm"
TOPC="$HOME/emulation/linux/crosstools"
CROSS="$TOPC/bin"
PREFIX="$TOPC/opt/cross"
SYSROOT="$TOPC/sysroot"
PATH="$PREFIX/bin:$PATH"
CORES=$(nproc)  # replace with 1 if multicore fails

BINUTIL="2.36.1"
GCC="11.1.0"
KERNEL="5.12.5"
MUSL="1.2.1"
NEWLIB="4.1.0"
MUSLDO=false

#----------------------------------------------------------------------
function Download {
    echo "[ Creating folders ]"
    mkdir -pv ${TOPC}/sources
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
    tar xzf ${TOPC}/sources/binutils-$BINUTIL.tar.gz -C ${TOPC}/sources
    cd ${TOPC}/sources/binutils-$BINUTIL/
    echo "  [ Configuring ]"
    mkdir build
    cd build
    ../configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror --enable-shared --enable-64-bit-bfd
    echo "  [ Compiling ]"
    make all -j$CORES
    echo "  [ Installing ]"
    make install
}

#----------------------------------------------------------------------
function GCC_step1 {
    echo "[ GCC ]"
    echo "  [ Extracting ]"
    tar xzf ${TOPC}/sources/gcc-$GCC.tar.gz -C ${TOPC}/sources
    cd ${TOPC}/sources/gcc-$GCC/
    which -- $TARGET-as || { echo "$TARGET-as is not in the PATH"; exit 1; }
    echo "  [ Configuring ]"
    mkdir build
    cd build
    if [ "$MUSLDO" = true ]; then
        ../configure --target=$TARGET --prefix="$PREFIX" --disable-nls \
                     --enable-languages=c,c++ \
                     --without-headers \
                     --with-gnu-as --with-gnu-ld
    else
        ../configure --target=$TARGET --prefix="$PREFIX" \
                     --without-headers --with-newlib \
                     --with-gnu-as --with-gnu-ld
    fi
    echo "  [ Compiling ]"
    make all-gcc -j$CORES
    echo "  [ Installing ]"
    make install-gcc
}

#----------------------------------------------------------------------
function LinuxHeaders {
    echo "[ Linux Headers ]"
    echo "  [ Extracting ]"
    tar xJf ${TOPC}/sources/linux-$KERNEL.tar.xz -C ${TOPC}/sources
    cd ${TOPC}/sources/linux-$KERNEL/
    echo "  [ Make proper ]"
    make mrproper
    echo "  [ Installing ]"
    make ARCH=${ARCH} headers_check
    make ARCH=${ARCH} INSTALL_HDR_PATH=${SYSROOT}/usr headers_install
}

#----------------------------------------------------------------------
function Musl {
    echo "[ Musl ]"
    echo "  [ Extracting ]"
    tar xzf ${TOPC}/sources/musl-$MUSL.tar.gz -C ${TOPC}/sources
    cd ${TOPC}/sources/musl-$MUSL/
    echo "  [ Configuring ]"
    ./configure --prefix=$PREFIX --target=$TARGET --syslibdir=$SYSROOT/lib
    echo "  [ Make ]"
    make -j$CORES
    echo "  [ Install ]"
    make install
}

#----------------------------------------------------------------------
function Newlib {
    echo "[ Newlib ]"
    echo "  [ Extracting ]"
    tar xzf ${TOPC}/sources/newlib-$NEWLIB.tar.gz -C ${TOPC}/sources
    cd ${TOPC}/sources/newlib-$NEWLIB/
    echo "  [ Configuring ]"
    mkdir build
    cd build
    ../configure --target=$TARGET --prefix=$PREFIX
    echo "  [ Make ]"
    make all -j$CORES
    echo "  [ Install ]"
    make install
}

#----------------------------------------------------------------------
function GCC_step2 {
    echo "[ GCC step 2]"
    cd ${TOPC}/sources/gcc-$GCC/build
    echo "  [ Configuring ]"
    ../configure --target=$TARGET --prefix=$PREFIX \
                 --with-newlib --with-gnu-as --with-gnu-ld \
                 --disable-shared --disable-libssp
    echo "  [ Compiling ]"
    make all -j$CORES
    echo "  [ Installing ]"
    make install
}

#----------------------------------------------------------------------
function Glibc {
echo "[ Glibc ]"
    echo "  [ Extracting ]"
    tar xzf ${TOPC}/sources/newlib-$NEWLIB.tar.gz -C ${TOPC}/sources
    cd ${TOPC}/sources/newlib-$NEWLIB/
    echo "  [ Configuring ]"
    mkdir build
    cd build
    ../configure --target=$TARGET --prefix=$PREFIX
    echo "  [ Make ]"
    make all -j$CORES
    echo "  [ Install ]"
    make install
}

#----------------------------------------------------------------------

function Test {
    echo "[ Test ]"
    mkdir -p ${SYSROOT}/usr/include
    mkdir -p ${SYSROOT}/usr/lib
    mkdir -p ${SYSROOT}/libs

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

    ${PREFIX}/bin/$TARGET-gcc --sysroot=${SYSROOT} -v
    ${PREFIX}/bin/$TARGET-gcc --sysroot=${SYSROOT} -g -o hello ${TOPC}/hello.c -static -L${SYSROOT}/usr/lib -I${SYSROOT}/usr/include
}

#----------------------------------------------------------------------
function delete {
    cd ${TOPC}
    rm -rf opt/
    echo "Removed all files except the sources directory"
    exit 1
}

#----------------------------------------------------------------------
# process commandline arguments
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -d|-delete|-deleteall)
    delete
    shift
    ;;
    -t|-test)
    Test 
    exit 1
    shift
    ;;
    -glibc|-c)
    CLIB=glibc
    shift
    ;;
    -musl|-m)
    CLIB=musl
    MUSLDO=true
    shift
    ;;
    -newlib|-n)
    CLIB=newlib
    shift
    ;;
esac
done

Download
Binutils
GCC_step1
LinuxHeaders
echo $CLIB
case $CLIB in
    newlib)
        Newlib
        ;;
    musl)
        Musl
        ;;
    glibc)
        Glibc
        ;;
    libc)
        Libc
        ;;
    picolibc)
        Picolibc
        ;;
    *)
        echo "no libc set or chosen" 
        exit 1
        ;;
esac
GCC_step2
Test
