#!/bin/bash
touch /var/lock/subsys/local
bash /home/Lowji194/boot_iptables.sh
bash /home/Lowji194/boot_ifconfig.sh 2>/dev/null
ulimit -n 1000048
/usr/local/etc/LowjiConfig/bin/StartProxy /usr/local/etc/LowjiConfig/UserProxy.cfg