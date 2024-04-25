#!/bin/bash
touch /var/lock/subsys/local
bash /home/anonyx/boot_iptables.sh
bash /home/anonyx/boot_ifconfig.sh
ulimit -n 1000048
/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg