#!/bin/bash

hostName=$1
targetIp=$(./get_ip.sh $hostName)
pubKey=$(cat /root/.ssh/id_rsa.pub)
ansibleTarget=/etc/ansible/dev-hosts
ansibleTargetName=$hostName

if [ "X${hostName}" = "X" ]; then
  exit 1
fi

if [ ! -f $ansibleTarget ]; then
  echo "[${ansibleTargetName}]
$targetIp
" > $ansibleTarget
fi

ansible -i $ansibleTarget $1 -m shell -a "mkdir -p /root/.ssh; cat << EOF > /root/.ssh/authorized_keys
$pubKey
EOF
chmod 600 /root/.ssh/authorized_keys ; \
chmod 700 /root/.ssh ; \
sed -i 's/#PermitRootLogin yes/PermitRootLogin without-password/' /etc/ssh/sshd_config ; \
service sshd restart ;
" -k -v
