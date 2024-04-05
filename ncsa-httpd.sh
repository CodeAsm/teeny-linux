#!/bin/sh
. ./vars.sh
NCSA="1.5.2a"                   #NCSA release number
ARCH="x86_64"                    #default arch
TARGET=$TOP/build
                                 #location for the build, change this for your location

#COMPILER="CC=musl-gcc"

#-----------------------------------------------------------------------

# first stuff happening here.
mkdir -p $TARGET
cd $TARGET

# a bunch of helpfull functions
#----------------------------------------------------------------------
function delete {
cd $TARGET
#mv ..master.zip ../../
#need to remove only dropbear stuff instead of everything
rm -rf usr/
rm -rf ../ncsa-httpd-$NCSA/

#cp ../../dropbear-$DROP.tar.bz2 ../dropbear-$DROP.tar.bz2
exit 1
}

function extract {
    echo "[ extract ncsa-httpd ]"
    cd $TARGET/..
    unzip ncsa-httpd-1.5.2_master.zip
}

function build {
    echo "[ building ncsa-httpd ]"
    cd $TARGET/../ncsa-httpd-master/

    make linux   #-j8 $COMPILER #PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp"
}

function install {
    echo "[ install ncsa-httpd ]"
    cd $TARGET/../ncsa-httpd-master/
    mkdir -p $TARGET/bin/
    #unlink $TARGET/../initramfs/x86-busybox/usr/bin/httpd #bug fix
    cp httpd $TARGET/bin/
    mkdir -p $TARGET/usr/sbin/
    ln -sf /bin/httpd $TARGET/usr/sbin/httpd

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
    ;;
esac
done

#Download if nececairy, clean an unclean build
#wget doesnt download if its already there, so no if
if [ ! -f ${TARGET}/../ncsa-httpd-1.5.2_master.zip ]; then
        wget -c https://github.com/seal331/ncsa-httpd/archive/refs/heads/master.zip -O ${TARGET}/../ncsa-httpd-1.5.2_master.zip
fi
#if [ ! -f $TARGET/usr/sbin/httpd ]; then
        extract
        build
        install
#fi
echo "[ done ] files should be in" $TARGET
