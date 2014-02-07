#!/bin/sh

set -x

hosts=$1
src=$2
dst=$3

if hostname |grep "cld-r" ; then
  l=r
else
  l=s
fi 

for i in $(ansible -i /etc/ansible/hosts_${l} $hosts --list-hosts)
do
  scp $src ${i}:/${dst}
  ssh ${i} "md5sum ${dst}"
done

md5sum ${src}

exit 0
