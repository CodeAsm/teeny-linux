#!/bin/sh
. ./vars.sh

#The next programs will be test to exist
programs=(tar ${COMPILER:3} touch make sed wget qemu-system-$ARCH cpio gzip cat bc)

echo "======================================"
echo "||  Teeny Linux  Build script       ||"
echo "======================================"
echo ""
echo "Requirements check:"

mkdir -p $TOP
if [ -d $TOP ]; then
  #  echo "\$TOP excists: $TOP"
    mkdir $TOP/test094422
    if [ -d $TOP/test094422 ]; then
       # echo "\$TOP writable"
        if ! command rm -rf $TOP/test094422/
        then
            echo "Cannot remove files/folders at \$TOP"
            exit 1;
        fi
    else
        echo "\$TOP: $TOP not writable"
        echo "One requirement is to change variables inside vars.sh"
        echo " as needed for your particular system."
        exit 1;
    fi
else
    echo "\$TOP: $TOP does not exist"
    echo "One requirement is to change variables inside vars.sh "
    echo "as needed for your particular system."
    exit 1;
fi

for program in ${programs[@]}
    do
       # echo "$program"                        #enable for debug
        if ! command -v $program &> /dev/null
        then
            echo "You need to install $program"
            exit 1;
        fi
done

if ! ls /usr/lib/musl/ > /dev/null ; then
    echo "Please install musl linux headers, arch knows a package called: kernel-headers-musl"
    exit 1;
fi

if ! command touch $TOP/test4449 &> /dev/null
then
    echo "Cannot create files at \$TOP"
    exit 1;
fi
if ! command chmod +x $TOP/test4449 
then
    echo "Cannot change permissions at \$TOP"
    exit 1;
fi

## Test to see if we can build a program
cat << EOF > $TOP/hello.c
#include <stdio.h>
int main()
{
	printf("Hello from teenylinux requirements test.\n");
	return 0;	
}
EOF

${COMPILER:3} -o $TOP/hello $TOP/hello.c

if ! command $TOP/hello
then
    echo "Cannot compile programs, check compiler"
    exit 1;
fi

#cleanup. 
rm $TOP/test4449
rm $TOP/hello
rm $TOP/hello.c
    echo "All checks passed"
    echo ""

