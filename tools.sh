#!/bin/bash
KERNEL="4.20.12"
ARCH="x86_64"
BINUTIL="2.32"
GCC="8.2.0"
MPFR="4.0.2"
GMP="6.1.2"
MPC="1.1.0"
GLIBC="2.29"    
TOP=$HOME/Projects/Emulation/Linux/tools  

#DO NOT EDIT BELOW it should not be nececairy.
#-----------------------------------------------------------
#first stuff happening here.
mkdir -p $TOP
cd $TOP


#-----------------------------------------------------------------------
# compile the thing
function MakeGCC {
cd $TOP
#do magic
fi

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

MakeGCC
