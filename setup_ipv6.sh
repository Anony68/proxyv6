#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
IPV6ADDR=IPV6_PREFIX:f816:3eff:fe8e:68a1
IPV6_DEFAULTGW=IPV6_PREFIX::1
Eth=$(ip addr show | grep -E '^2:' | sed 's/^[0-9]*: \(.*\):.*/\1/')

echo "IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
IPV6ADDR=$IPV6ADDR/64
IPV6_DEFAULTGW=$IPV6_DEFAULTGW" >> /etc/sysconfig/network-scripts/ifcfg-$Eth
service network restart