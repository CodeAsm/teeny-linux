
# Network tips and tricks

Qemu supports networks and just like normal hardware, if your network device has support build into the kernel (not as a module, unless you build those modules and know how to load them) should work.

To get basic network working, the current buildscipt and setup of qemu will use basic networking.
The IP will be 10.0.2.15 and you can reach the internet if your host and qemu allows other virtual machines aswell.

Build and/or start a instance with a mac adress of choice

```bash
./build.sh -net <macaddr>
```

for example

```bash
./build.sh -net 52:55:00:d1:55:01
```

Will run a VM with that specific macaddr (you need to change the ip inside or do DHCP trickery).

## Bridge 

To use a bridge setup (wich I wanted to try anyway) and be able to ping another virtual machine do the following:
Create a bridge and 2 taps (1 tap for a virual machine, either eth0/or wireless for internet, or another tap for another virtual machine).
As root (or use sudo)

```sh
ip tuntap add tap0 mode tap
ip tuntap add tap1 mode tap
```

Create the actual bridge

```sh
brctl  addbr br0
```

Add the two taps to the bridge

```sh
brctl addif br0 tap0
brctl addif br0 tap1
```

Bring the interfaces up, so they actualy work.

```sh
ifconfig tap0 up
ifconfig tap1 up
ifconfig br0 up
```

then add a network device to your qemu instance, if using my buildscript, run the following

```sh
./build -net 52:55:00:d1:55:01
```

The system should get an IP from your dhcp server (you can also add one using dnsmasq)

sometimes you need to change the ip of an instance, then
inside one of the qemu instances, change to static ip for example:

```sh
ifconfig eth0 down
ifconfig eth0 up 10.0.2.16 netmask 255.255.255.0 up
```

And now you should be able to ping eachother and do stuff. If you setup a DHCP server or add the bridge to a network with a DHCP server, you can set the instances to recieve a IP from the said DHCP server, which in the current version is the case.

## Dropbear


In case of dropbear, if the right keys are in place, starting with network support:

```sh
./build.sh -net 52:55:00:d1:55:01
```

then inside the system:

```sh
dropbear -R
```

You should now be able to ssh into this (maybe remove the old known host ip and key from your hosts .ssh/known_hosts)

```sh
ssh root@192.168.66.6
```

__tip__
add the following to prevent a bloating knownhosts file.

```sh
-o "UserKnownHostsFile /dev/null"
```
