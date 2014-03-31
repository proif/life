#!/bin/bash

megaClicmd=$(which MegaCli)
ldInfo=$($megaClicmd -ldinfo -l0 -a0)
ldState=$(echo "$ldInfo" |grep -i State |awk -F ': ' '{print $NF}')
echo $ldState
#State               : Optimal

if [ X${ldState} = XOptimal ]; then
  retCode=0
else
  retCode=1
fi

/usr/local/bin/zabbix_trap.sh megacli.raid.state $retCode
