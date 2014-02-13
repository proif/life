#!/bin/bash
#####                                            #####
##### call_vpn.sh Backup to Master trigger       #####
#####                                            #####

#####Variable######
nameHost=$(hostname)
#localHostSuffix=$(echo $nameHost |awk -F '-' '{print $NF}')
pathSelf=/usr/local/bin
pathLog=/var/log/vpn_call.log
callScript=call_vpn.sh
#flagDebug=0 #debug flag

#####Function#####
. ${pathSelf}/functions

echo "##### VPN Server:${hostname} vrrp state change Backup to Master. VPN Connect Script Start." |tee -a ${pathLog}

#####addr chek#####
chk_ipaddr ${addrInitiateVip} 5 3 #addr count interval
if [ $? -eq 1 ]; then
  echo "check ${addrInitiateVip} failed" |tee -a ${pathLog}
fi

chk_ipaddr ${addrLocalVip} 5 3
if [ $? -eq 1 ]; then
  echo "check ${addrLocalVip} failed" |tee -a ${pathLog}
fi

#####connect#####
ssh ${addrInitiateVip} "sh ${pathLog}/${callScript}"

exit 0
