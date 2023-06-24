#!/bin/bash

cat > /etc/hosts <<EOF
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

192.168.1.213 mac1
192.168.1.214 nuc1
192.168.1.215 nuc2
192.168.1.216 nuc3

EOF

export int="eno1"

if [ $1 == "nuc1" ]; then
    export ip1="214"
    export ip2="224"
elif [ $1 == "nuc2" ]; then
    export ip1="215"
    export ip2="225"
elif [ $1 == "nuc3" ]; then
    export ip1="216"
    export ip2="226"
elif [ $1 == "mac1" ]; then
    export ip1="213"
    export ip2="223"
    sed -i 's/^#HandleLidSwitch=suspend/HandleLidSwitch=ignore/g'  /etc/systemd/logind.conf
    systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
    export int="enp1s0f0"
else
    echo "Host not found"
    exit 1
fi

cat > /etc/netplan/00-installer-config.yaml <<EOF
network:
  version: 2
  ethernets:
    ${int}:
      dhcp4: no

  bridges:
    br-mgmt:
      addresses:
        - 192.168.10.${ip2}/24
      interfaces: [ vlan.10 ]
    br-storage:
      addresses:
        - 192.168.20.${ip2}/24
      interfaces: [ vlan.20 ]
    br-vxlan:
      addresses:
        - 192.168.30.${ip2}/24
      interfaces: [ vlan.30 ]
    br-vlan:
      interfaces: [ ${int} ]
      addresses:
        - 192.168.1.${ip1}/24
      nameservers:
        addresses: [192.168.1.1, 8.8.8.8]
      routes:
        - to: default
          via: 192.168.1.1

  vlans:
    vlan.10:
      id: 10
      link: ${int}
    vlan.20:
      id: 20
      link: ${int}
    vlan.30:
      id: 30
      link: ${int}
EOF

netplan apply

apt update ; apt install vim bash-completion wget iputils-ping traceroute vim wget dnsutils -y

echo "flamarion ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

sed -i 's/#PermitRootLogin.*/PermitRootLogin\  yes/g' /etc/ssh/sshd_config
systemctl restart sshd
reboot