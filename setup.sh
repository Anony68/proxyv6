VLAN=1
#
Proxy_Count=1000
#
USER_PORT=""
#
FIRST_PORT=12152
#
PASS=0
#

IPV6ADDR=IPV6_PREFIX:f816:3eff:fe8e:68a1
IPV6_DEFAULTGW=IPV6_PREFIX::1

#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

Eth=$(ip addr show | grep -E '^2:' | sed 's/^[0-9]*: \(.*\):.*/\1/')

echo "IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
IPV6ADDR=$IPV6ADDR/64
IPV6_DEFAULTGW=$IPV6_DEFAULTGW" >> /etc/sysconfig/network-scripts/ifcfg-$Eth
service network restart

random() {
        tr </dev/urandom -dc A-Za-z0-9 | head -c5
        echo
}

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
gen64() {
        ip64() {
                echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
        }
        echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
}
LowjiProxy() {
    echo "installing LowjiProxy"
    cd /root
sleep 1
    URL="https://raw.githubusercontent.com/Anony68/proxyv6/main/Proxy.gz"
    wget -qO- $URL | bsdtar -xvf-
sleep 1
    cd /root/LowjiProxy
sleep 2
    make -f Makefile.Linux
    mkdir -p /usr/local/etc/LowjiConfig/{bin,logs,stat}
    cp src/3proxy /usr/local/etc/LowjiConfig/bin/
sleep 5
    cd $WORKDIR
}

download_proxy() {
echo "$PASS" > "${WORKDIR}/pass.txt"
echo "$IP4" > "${WORKDIR}/ip.txt"
echo "$IP6" > "${WORKDIR}/ip6.txt"
echo "hoàn tất"
}
gen_proxy() {
    cat <<EOF
daemon
maxconn 2000
nserver 1.1.1.1
nserver 8.8.4.4
nserver 2001:4860:4860::8888
nserver 2001:4860:4860::8844
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
stacksize 6291456
flush
auth strong

users $(awk -F "/" 'BEGIN{ORS="";} {print $1 ":CL:" $2 " "}' ${WORKDATA})


$(awk -F "/" -v PASS="$PASS" '{
    auth = (PASS == 1 || $3 == $5) ? "strong" : "none";
    proxy_type = ($3 != $5) ? "-6" : "-4" ;
    print "auth " auth;
    print "allow  " $1;
    print "proxy " proxy_type " -n -a -p" $4 " -i" $3 " -e" $5;
    print "flush";
}' ${WORKDATA})
EOF
}

gen_proxy_file() {
cat > /root/proxy.txt <<EOF
$(awk -F "/" -v LAST_PORT="$LAST_PORT" -v PASS="$PASS" '{
    if ($4 <= LAST_PORT) {
                print $3 ":" $4
    } else {
        print $3 ":" $4 ":" $1 ":" $2 > "/root/ip4.txt";    # Ghi dòng vào ip4.txt
    }
}' ${WORKDATA})
EOF
sed 's/$/^M/' /root/proxy.txt
}

gen_proxy_file_for_user() {
cat > /root/proxy.txt <<EOF
$(awk -F "/" -v LAST_PORT="$LAST_PORT" -v PASS="$PASS" '{
    if ($4 <= LAST_PORT) {
                print $3 ":" $4 ":" $1 ":" $2
    } else {
        print $3 ":" $4 ":" $1 ":" $2 > "/root/ip4.txt";    # Ghi dòng vào ip4.txt
    }
}' ${WORKDATA})
EOF
}


gen_data() {
    unique_ipv6_list=()  # Mảng để lưu trữ các giá trị IPv6 duy nhất

    seq $FIRST_PORT $LAST_PORT | while read port; do
        ipv6="$(gen64 $IP6)"
        while [[ " ${unique_ipv6_list[@]} " =~ " $ipv6 " ]]; do
            ipv6="$(gen64 $IP6)"
        done
        unique_ipv6_list+=("$ipv6")

        echo "${USER_PORT}${port}/$(random)/$IP4/$port/$ipv6"
    done
        V4Port=$((LAST_PORT + 1))
        echo "${USER_PORT}${V4Port}/$(random)/$IP4/$V4Port/$IP4"
}

gen_iptables() {
    cat <<EOF
    $(awk -F "/" '{print "iptables -I INPUT -p tcp --dport " $4 "  -m state --state NEW -j ACCEPT"}' ${WORKDATA})
EOF
}

gen_ifconfig() {
    cat <<EOF
$(awk -F "/" -v Eth="${Eth}" '{print "ifconfig " Eth " inet6 add " $5 "/64"}' ${WORKDATA} | sed '$d')
EOF
}
echo "installing net-tools"
yum -y install wget gcc net-tools bsdtar zip >/dev/null

cat << EOF > /etc/rc.d/rc.local
#!/bin/bash
touch /var/lock/subsys/local
EOF

echo "working folder = /home/Lowji194"
WORKDIR="/home/Lowji194"
WORKDATA="${WORKDIR}/data.txt"
mkdir $WORKDIR && cd $_


IP4=$(ip addr show "$Eth" | awk '/inet / {print $2}' | head -1 | cut -d '/' -f 1)
IP6=$(ip addr show "$Eth" | grep 'inet6' | grep 'global' | awk '{print $2}' | awk -F ":" '{print $1":"$2":"$3":"$4}' | head -n 1)

echo "Internal ip = ${IP4}. Exteranl sub for ip6 = ${IP6}. Enether = ${Eth}"
curl -sO https://raw.githubusercontent.com/Anony68/proxyv6/main/start.sh -P "/root"
chmod 0777 /root/start.sh
#call Install LowjiProxy
LowjiProxy


LAST_PORT=$(($FIRST_PORT + (Proxy_Count - 1)))
echo "LAST_PORT is $LAST_PORT. Continue..."

gen_data >$WORKDIR/data.txt
gen_iptables >$WORKDIR/boot_iptables.sh
gen_ifconfig >$WORKDIR/boot_ifconfig.sh
if [ "$VLAN" -eq 1 ]; then
    curl -sO https://raw.githubusercontent.com/Anony68/proxyv6/main/VLAN.sh -P "${WORKDIR}"
chmod 0755 ${WORKDIR}/VLAN.sh
sed -i 's/\r$//' ${WORKDIR}/VLAN.sh
fi

gen_proxy >/usr/local/etc/LowjiConfig/UserProxy.cfg
mv /usr/local/etc/LowjiConfig/bin/3proxy /usr/local/etc/LowjiConfig/bin/StartProxy
chmod +x /usr/local/etc/LowjiConfig/bin/StartProxy

cat >/etc/rc.local <<EOF
#!/bin/bash
touch /var/lock/subsys/local
bash ${WORKDIR}/boot_iptables.sh
bash ${WORKDIR}/boot_ifconfig.sh 2>/dev/null
ulimit -n 1000048
/usr/local/etc/LowjiConfig/bin/StartProxy /usr/local/etc/LowjiConfig/UserProxy.cfg
EOF
chmod 0755 /etc/rc.local
bash /etc/rc.local
if [ "$VLAN" -eq 1 ]; then
    echo "bash ${WORKDIR}/VLAN.sh" >> /etc/rc.local
fi

gen_proxy_file

echo "Starting Proxy"
download_proxy