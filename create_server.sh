#!/bin/bash

name="SRVNAME"
archid="ARCHIVEID"
pass="DEFAULTPASS"
zone="ZONEID"
plan="SRVPLAN"
diskplan="2OR4"
disksize="DISKSIZE"

#31001
#hdd:2 ssd:4

# 1001:プラン/1Core-1GB       16008:プラン/8Core-16GB     3003:プラン/3Core-3GB       48010:プラン/10Core-48GB    64010:プラン/10Core-64GB
# 12003:プラン/3Core-12GB     2001:プラン/1Core-2GB       32006:プラン/6Core-32GB     48012:プラン/12Core-48GB    64012:プラン/12Core-64GB
# 12004:プラン/4Core-12GB     2002:プラン/2Core-2GB       32008:プラン/8Core-32GB     5001:プラン/1Core-5GB       8003:プラン/3Core-8GB
# 12005:プラン/5Core-12GB     24005:プラン/5Core-24GB     32010:プラン/10Core-32GB    5002:プラン/2Core-5GB       8004:プラン/4Core-8GB
# 12006:プラン/6Core-12GB     24006:プラン/6Core-24GB     4001:プラン/1Core-4GB       5003:プラン/3Core-5GB       8005:プラン/5Core-8GB
# 128012:プラン/12Core-128GB  24008:プラン/8Core-24GB     4002:プラン/2Core-4GB       5004:プラン/4Core-5GB       96012:プラン/12Core-96GB
# 16004:プラン/4Core-16GB     24010:プラン/10Core-24GB    4003:プラン/3Core-4GB       6002:プラン/2Core-6GB
# 16005:プラン/5Core-16GB     3001:プラン/1Core-3GB       4004:プラン/4Core-4GB       6003:プラン/3Core-6GB
# 16006:プラン/6Core-16GB     3002:プラン/2Core-3GB       48008:プラン/8Core-48GB     6004:プラン/4Core-6GB

# 112400500863:FreeBSD_8.3_64bit_(基本セット)                112600051846:Windows_Server_2012_R2_Datacenter_Edition
# 112400500864:FreeBSD_8.3_64bit_(基本セット)                112600051958:Windows_Server_2008_R2_for_RDS(MS_Office付)
# 112500127179:Vyatta_Core_6.5R1_32bit_(6rd対応)             112600078947:FreeBSD_9.2_64bit_(基本セット)
# 112500213364:Ubuntu_Server_13.04_64bit_(基本セット)        112600078948:FreeBSD_9.2_64bit_(基本セット)
# 112500213598:Ubuntu_Server_13.04_64bit_(基本セット)        112600078993:FreeBSD_10.0_64bit_(基本セット)
# 112500459149:Ubuntu_Server_12.04.3_LTS_64bit_(基本セット)  112600078994:FreeBSD_10.0_64bit_(基本セット)
# 112500459481:Ubuntu_Server_12.04.3_LTS_64bit_(基本セット)  112600081771:Zabbix_archve
# 112500489806:Ubuntu_Server_13.10_64bit_(基本セット)        112600098190:Debian_GNU/Linux_6.0.9_64bit_(基本セット)
# 112500489823:Ubuntu_Server_13.10_64bit_(基本セット)        112600098191:Debian_GNU/Linux_6.0.9_64bit_(基本セット)
# 112500513592:CentOS_5.10_64bit_(基本セット)                112600098267:Debian_GNU/Linux_7.4.0_64bit_(基本セット)
# 112500513643:CentOS_5.10_64bit_(基本セット)                112600098303:Debian_GNU/Linux_7.4.0_64bit_(基本セット)
# 112500570402:CentOS_6.5_64bit_(基本セット)                 112600128302:Scientific_Linux_6.5_64bit_(基本セット)
# 112500570421:CentOS_6.5_64bit_(基本セット)                 112600128304:Scientific_Linux_6.5_64bit_(基本セット)
# 112600032371:Windows_Server_2008_R2_Datacenter_Edition     112600321612:Ubuntu_Server_14.04_LTS_64bit_(基本セット)
# 112600051011:Windows_Server_2008_R2_for_RDS                112600321661:Ubuntu_Server_14.04_LTS_64bit_(基本セット)

sacloud create server zone $zone plan $plan name ${name}
id=$(sacloud show server $name --tsv |awk '{print $1}' |grep -E "[0-9]+")
sacloud create interface to server $id
intid=$(sacloud show server $id |grep interface |awk '{print $4}' |grep -oE "[0-9]{12}")
sacloud connect interface $intid to switch shared

sacloud create disk zone $zone plan $diskplan size $disksize type virtio name $name
diskid=$(sacloud show disk |grep $name |tail -n2 |grep -oE "[0-9]{12}")
sacloud copy archive $archid to disk $diskid

while :
do
  progress=$(sacloud show disk $diskid |grep progress |awk '{print $4}')
  if [ ${progress} = "100%" ]; then
    break
  fi
  sleep 5
done

sacloud attach disk $diskid to server $id
sacloud modify disk $diskid password $pass hostname $name
