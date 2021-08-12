#!/bin/bash 
TARGET="powerpc64-unknown-linux-gnu" #default powerpc64-linux
ARCH="powerpc"
HOST="x86_64"
CLIB=glibc
TOPC="$HOME/Projects/Emulation/Linux/crosstools"
CROSS="$TOPC/bin"
PREFIX="$TOPC"
PATH="$CROSS::/bin:/usr/bin"
CORES=$(nproc)  #replace with 1 if multicore fails
BUILD64="-m64" #Obvisously needed, especially glibc

BINUTIL="2.36.1"
GCC="11.1.0"
KERNEL="5.12.5"
MUSL="1.2.1"
NEWLIB="4.1.0"
GLIBC="2.33"
GMP=""
MPC=""
MPFR=""
ISL=""

export PATH 
export BUILD64
unset CFLAGS CXXFLAGS
echo $PATH
echo $CFLAGS
echo $CXXFLAGS


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

${GMP}
${MPC}
${MPFR}
${ISL}

wget -c https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$KERNEL.tar.xz -P ${TOPC}/sources
if [ "$MUSLDO" = true ]; then
    wget -c https://musl.libc.org/releases/musl-$MUSL.tar.gz -P ${TOPC}/sources
else
    wget -c https://sourceware.org/pub/newlib/newlib-$NEWLIB.tar.gz -P ${TOPC}/sources
fi
wget -c https://ftp.gnu.org/gnu/libc/glibc-$GLIBC.tar.gz -P ${TOPC}/sources
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
AR=ar AS=as ../configure --target=$TARGET --prefix="$PREFIX" \
            --host=${HOST} --with-sysroot=${TOPC} \
            --with-lib-path=${TOPC}/lib \
            --disable-nls --disable-werror \
            --disable-static --enable-64-bit-bfd --disable-multilib \
            2>&1 | tee $TOPC/binutils_config_log.txt
echo "  [ Compiling ]"
make all -j$CORES  2>&1 | tee $TOPC/binutils_build_log.txt
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
# mkdir build moved into config specific

echo -en '\n#undef STANDARD_STARTFILE_PREFIX_1\n#define STANDARD_STARTFILE_PREFIX_1 "'${TOPC}'/lib/"\n' >> gcc/config/rs6000/sysv4.h
echo -en '\n#undef STANDARD_STARTFILE_PREFIX_2\n#define STANDARD_STARTFILE_PREFIX_2 ""\n' >> gcc/config/rs6000/sysv4.h

touch ${TOPC}/include/limits.h

mkdir build
cd build
echo $PWD

# --with-mpfr=${TOPC} --with-gmp=${TOPC} \
#    --with-isl=${TOPC} --with-cloog=${TOPC} --with-mpc=${TOPC} \
AR=ar LDFLAGS="-Wl,-rpath,${TOPC}/lib" \
    ../configure --prefix=${TOPC} \
    --build=${HOST} --host=${HOST} --target=${TARGET} \
    --with-sysroot=${TOPC} --with-local-prefix=${TOPC} \
    --with-native-system-header-dir=${TOPC}/include --disable-nls \
    --disable-shared    \
    --without-headers --with-newlib --disable-decimal-float --disable-libgomp \
    --disable-libmudflap --disable-libssp --disable-libatomic --disable-libitm \
    --disable-libsanitizer --disable-libquadmath --disable-threads \
    --disable-multilib --disable-target-zlib --with-system-zlib \
    --enable-languages=c --enable-checking=release


echo "  [ Compiling ]"
make all-gcc -j$CORES 2>&1 | tee $TOPC/gcc-step1_build_log.txt
make all-target-libgcc -j$CORES 2>&1 | tee $TOPC/gcc-step1_build-libgcc_log.txt

echo "  [ Installing ]"
make install-gcc  2>&1 | tee $TOPC/gcc-step1_install_log.txt
make install-target-libgcc  2>&1 | tee $TOPC/gcc-step1_install-libgcc_log.txt

echo "  [ Cleaning ]"
cd ${TOPC}/sources/gcc-$GCC/
rm -rf build
}
#----------------------------------------------------------------------

function GCC_step2 {
echo "[ GCC step 2]"
cd ${TOPC}/sources/gcc-$GCC/

echo "  [ Compiling second time ]"
mkdir build
cd build
echo $PWD

CC=${TARGET}-gcc ../configure --target=$TARGET --prefix=$PREFIX \
                --with-newlib --with-gnu-as --with-gnu-ld \
                --disable-shared --disable-libssp \
                --with-headers=${$PREFIX}/include \
                --enable-multilib --disable-shared --disable-thread 2>&1 | tee $TOPC/gcc-step2_config_log.txt

echo "  [ Compiling ]"
make all -j$CORES 2>&1 | tee $TOPC/gcc-step2_build_log.txt

echo "  [ Installing ]"
make install  2>&1 | tee $TOPC/gcc-step2_install_log.txt
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
#------------------------------------------------------------------------
function Glibc {
echo "[ Glibc ]"
echo "  [ Extracting ]"

pv ${TOPC}/sources/glibc-$GLIBC.tar.gz | tar xzf - -C ${TOPC}/sources
cd ${TOPC}/sources/glibc-$GLIBC/

echo "  [ configure ]"
cp -v timezone/Makefile{,.orig}
sed 's/\\$$(pwd)/`pwd`/' timezone/Makefile.orig > timezone/Makefile

mkdir ../glibc_build
cd ../glibc_build

echo "libc_cv_ssp=no" > config.cache
BUILD_CC="gcc" CC="${TARGET}-gcc -m64" \
      AR="${TARGET}-ar" RANLIB="${TARGET}-ranlib" \
      ../glibc-${GLIBC}/configure --prefix=$PREFIX \
      --host=${TARGET} --build=${HOST} \
      --disable-profile --enable-kernel=${KERNEL} \
      --with-binutils=${TOPC}/bin --with-headers=${TOPC}/include \
      --enable-obsolete-rpc --cache-file=config.cache --disable-werror
    # --disable-werror scary booboo option
    # for http://patches-tcwg.linaro.org/patch/40709/

echo "  [ Make ]"
make 2>&1 | tee $TOPC/glibc_build_log.txt
echo "  [ Install ]"
make install  2>&1 | tee $TOPC/glibc_install_log.txt
echo "  [ Cleaning ]"
cd ${TOPC}/sources/
#rm -rf linux-$KERNEL/
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

${PREFIX}/bin/$TARGET-gcc -g -o hello ${TOPC}/hello.c -static -L${TOPC} -I${TOPC} 2>&1 | tee $TOPC/sampletest.txt
#rm ${TOPC}/hello.c
}
#----------------------------------------------------------------------
function delete {
cd ${TOPC}
rm -rf libexec/
rm -rf $TARGET/
rm -rf share/
rm -rf lib/
rm -rf include/
rm -rf bin/
echo "Removed all files except the sources directory"
echo "logs are also still there, will be overwritten upon rerun"
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
    shift; # past argument and value
    ;;-glibc|-c)
    CLIB=glibc
    shift; # past argument and value
    ;;-newlib|-n)
    CLIB=newlib
    shift; # past argument and value
    ;;-libc|-lc)
    CLIB=libc
    shift; # past argument and value
esac
done

Download
LinuxHeaders
Binutils
GCC_step1  #static
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
        echo "nope";
        exit
        ;;
    picolibc)
        Picolibc
        ;;
    *)
        echo "no libc set or chosen" | tee $TOPC/missing-lib_log.txt
        exit 1
        ;;
esac
#GCC_step2
#Test
