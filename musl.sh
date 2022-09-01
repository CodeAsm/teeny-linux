#!/bin/sh
TARGET=$HOME/Projects/Emulation/Linux/bin/build    
                                 #location for the build, change this for your location
                               
# a bunch of helpfull functions
#----------------------------------------------------------------------
function delete {
cd $TARGET
mv ../x86_64-linux-musl-native.tgz ../../
#This so much, lets dell all. (dropbear doesnt, this one does, dirty)
rm -rf *

cp ../../x86_64-linux-musl-native.tgz ../x86_64-linux-musl-native.tgz
exit 1
}

function extract {
    echo "[ extract musl ]"
    cd $TARGET/..
    tar -xvf x86_64-linux-musl-native.tgz

}

function build {
    echo "" #there is no building
}

function install {
    echo "[ install musl ]"
    cd $TARGET/..
    cp -r x86_64-linux-musl-native/. build/
    cd $TARGET
    unlink $TARGET/usr
    mkdir -pv $TARGET/usr/include
    ln -s /include usr/include/i386-linux-gnu
    mkdir -pv $TARGET/usr/local
    ln -s /include usr/local/include
	    
    mkdir -pv $TARGET/var/lib/dpkg
    touch $TARGET/var/lib/dpkg/status
    cat << EOF > $TARGET/var/lib/dpkg/status
Package: musl
Status: install ok installed
Priority: optional
Section: dev
Version: 1.2.3

EOF
    
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
#if [ ! -f $TARGET/../dropbear-$DROP.tar.bz2 ]; then
        wget -c https://musl.cc/x86_64-linux-musl-native.tgz -P $TARGET/..
#fi
#if [ ! -f $TARGET/../dropbear-$DROP/README ]; then
        extract
#fi
#if [ ! -f $TARGET/../dropbear-$DROP/dropbear ]; then
#        build
#fi  
#if [ ! -f $TARGET/usr/sbin/dropbear ]; then
        install
#fi  
echo "[ done ] files should be in" $TARGET
