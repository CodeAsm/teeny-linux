#!/bin/sh
. ./vars.sh
DROP="2025.88"                   #Dropbear release number
ARCH="x86_64"                    #default arch
TARGET=$TOP/build    
                                 #location for the build, change this for your location
                                 
COMPILER="CC=musl-gcc" 
                                 
#-----------------------------------------------------------------------

# first stuff happening here.
mkdir -p $TARGET
cd $TARGET

# a bunch of helpfull functions
#----------------------------------------------------------------------
function delete {
cd $TARGET
mv ../dropbear-$DROP.tar.bz2 ../../
#need to remove only dropbear stuff instead of everything
rm -rf usr/
rm -rf ../dropbear-$DROP/

cp ../../dropbear-$DROP.tar.bz2 ../dropbear-$DROP.tar.bz2
exit 1
}

function extract {
    echo "[ extract dropbear ]"
    cd $TARGET/..
    tar -xvf dropbear-$DROP.tar.bz2 
}

function build {
    echo "[ building dropbear ]"
    cd $TARGET/../dropbear-$DROP
    ./configure             \
    --enable-static         \
    --disable-syslog        \
    --enable-bundled-libtom \
    --disable-lastlog       \
    --disable-utmp          \
    --disable-utmpx         \
    --disable-wtmp          \
    --disable-wtmpx         \
    --disable-zlib          \
    --disable-loginfunc     \
    --prefix=/usr/sbin/
    #--disable-pututline     \
    #--disable-pututxline    \
    
    make -j8 $COMPILER #PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp"
}

function install {
    echo "[ install dropbear ]"
    cd $TARGET/../dropbear-$DROP
    mkdir -pv $TARGET/usr/sbin/
    cp dropbear $TARGET/usr/sbin/
    cp dropbearkey $TARGET/usr/sbin/
    cp dropbearconvert $TARGET/usr/sbin/
    cp dbclient $TARGET/usr/sbin/
    mkdir -pv $TARGET/etc/dropbear/
    #cp ~/.ssh/id_rsa.pub $TARGET/etc/dropbear/authorized_keys
    #cp ~/.ssh/id_rsa.pub $TARGET/root/authorized_keys
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
if ! curl --output /dev/null --silent --head --fail "https://matt.ucc.asn.au/dropbear/releases/dropbear-$DROP.tar.bz2"; then
    echo "Primary server unavailable, trying mirror..."
    if ! curl --output /dev/null --silent --head --fail "https://dropbear.nl/mirror/releases/dropbear-$DROP.tar.bz2"; then
        echo "Both servers are unavailable. Exiting."
        exit 1
    else
        wget -c https://dropbear.nl/mirror/releases/dropbear-$DROP.tar.bz2 -P $TARGET/..
    fi
else
    wget -c https://matt.ucc.asn.au/dropbear/releases/dropbear-$DROP.tar.bz2 -P $TARGET/..
fi
#fi
if [ ! -f $TARGET/../dropbear-$DROP/README ]; then
        extract
fi
if [ ! -f $TARGET/../dropbear-$DROP/dropbear ]; then
        build
fi  
if [ ! -f $TARGET/usr/sbin/dropbear ]; then
        install
fi  
echo "[ done ] files should be in" $TARGET
