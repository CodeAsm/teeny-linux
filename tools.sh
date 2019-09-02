#!/bin/bash
KERNEL="4.20.12"                              #matches tested LFS tree, should later match with Kernel for
                                              # proper headers.
ARCH="x86_64-teeny-linux-gnu"                   #slightly diferent from build, this matches LFS
BINUTIL="2.32"
GCC="8.2.0"
MPFR="4.0.2"
GMP="6.1.2"
MPC="1.1.0"
GLIBC="2.29"    
TOP=$HOME/Projects/Emulation/Linux/tools      #location of the packages and building dirs, gets cleaned
PREFIX="/tools"                               #if you change this, the gcc 
                                              # will end up elsewhere in the initramfs 
ROOTLOC="$HOME/Projects/Emulation/Linux/root" #build.sh expects the gcc stuff to be here to copy 
                                              # it into the initramfs later.

#DO NOT EDIT BELOW HERE should not be nececairy.
#-----------------------------------------------------------
#first stuff happening here.
mkdir -p $TOP
cd $TOP


#-----------------------------------------------------------------------
# compile the thing
function MakeBIN1 {
cd $TOP
tar -xvf binutils-$BINUTIL.tar.xz
cd binutils-$BINUTIL/
mkdir -v build
cd       build

../configure --prefix=$TOP            \
             --with-sysroot=$TOP        \
             --with-lib-path=$TOP/lib \
             --target=$ARCH          \
             --disable-nls              \
             --disable-werror
make -j8
#-----------------------if x64
 mkdir -v $TOP/lib && ln -sv lib $TOP/lib64 
 
make install

rm -rf binutils-$BINUTIL/

}

#-----------------------------------------------------------------------
function MakeGCCP1 {
cd $TOP
tar -xvf gcc-$GCC.tar.xz
cd gcc-$GCC/

tar -xf ../mpfr-$MPFR.tar.xz
mv -v mpfr-$MPFR mpfr
tar -xf ../gmp-$GMP.tar.xz
mv -v gmp-$GMP gmp
tar -xf ../mpc-$MPC.tar.gz
mv -v mpc-$MPC mpc

---------------------- if x86_64
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac
--------------------------
mkdir -v build
cd       build
../configure                                       \
    --target=$ARCH                                 \
    --prefix=$TOP                                  \
    --with-glibc-version=2.11                      \
    --with-sysroot=$TOP                            \
    --with-newlib                                  \
    --without-headers                              \
    --with-local-prefix=$TOP                       \
    --with-native-system-header-dir=$TOP/include   \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libmpx                               \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++
    
    make -j8
    make install


rm -rf gcc-$GCC/
}
#-----------------------------------------------------------------------
function LinHeaders {
cd $TOP
tar -xvf linux-$KERNEL.tar.xz
cd linux-$KERNEL/
make mrproper
make INSTALL_HDR_PATH=dest headers_install
cp -rv dest/include/* $TOP/include

rm -rf linux-$KERNEL/
}
#-----------------------------------------------------------------------
function GlibC {
cd $TOP
tar -xvf glibc-$GLIBC.tar.xz
cd glibc-$GLIBC/

mkdir -v build
cd       build

../configure                             \
      --prefix=$TOP                    \
      --host=$ARCH                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=3.2                \
      --with-headers=$TOP/include
      
make
make install

rm -rf glibc-$GLIBC/
}
#-----------------------------------------------------------------------
function LibSTDC {
cd $TOP
tar -xvf gcc-$GCC.tar.xz
cd gcc-$GCC/

rm -rf gcc-$GCC/
}
#-----------------------------------------------------------------------
function MakeBIN2 {
cd $TOP
tar -xvf binutils-$BINUTIL.tar.xz
cd binutils-$BINUTIL/

rm -rf binutils-$BINUTIL/
}
#-----------------------------------------------------------------------
function MakeGCCP2 {
cd $TOP
tar -xvf gcc-$GCC.tar.xz
cd gcc-$GCC/

rm -rf gcc-$GCC/
}




#----------------------------------------------------------------------
#process commandline arguments
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -arch|-cpu)
    ARCH="$2"
    shift; shift # past argument and value
    ;;
esac
done

#sets defaults if arguments are empty or incorrect
if [ -z $ARCH ]; then
    ARCH="x86_64"; fi
    
cd $TOP

#Download if nececairy, clean an unclean build
if [ ! -f $TOP/linux-$KERNEL.tar.$KTYPE ]; then
        wget -c https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$KERNEL.tar.xz
fi
if [ ! -f $TOP/binutils-$BINUTIL.tar.xz ]; then
        wget -c http://ftp.gnu.org/gnu/binutils/binutils-$BINUTIL.tar.xz
fi
if [ ! -f $TOP/gcc-$GCC.tar.xz ]; then
        wget -c http://ftp.gnu.org/gnu/gcc/gcc-8.2.0/gcc-$GCC.tar.xz
fi
if [ ! -f $TOP/mpc-$MPC.tar.gz ]; then
        wget -c https://ftp.gnu.org/gnu/mpc/mpc-$MPC.tar.gz
fi
if [ ! -f $TOP/gmp-$GMP.tar.xz ]; then
        wget -c http://ftp.gnu.org/gnu/gmp/gmp-$GMP.tar.xz
fi
if [ ! -f $TOP/mpfr-$MPFR.tar.xz ]; then
        wget -c http://www.mpfr.org/mpfr-4.0.2/mpfr-$MPFR.tar.xz
fi
if [ ! -f $TOP/glibc-$GLIBC.tar.xz ]; then
        wget -c http://ftp.gnu.org/gnu/glibc/glibc-$GLIBC.tar.xz
fi

# Here we build all the software in order
MakeBIN1
MakeGCCP1
LinHeaders
GlibC
#LibSTDC
#MakeBIN2
#MakeGCCP2
