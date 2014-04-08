#!/bin/bash

TMP=$(mktemp) ; rcvPorts="8085 8086 8087"
echo "$(ps auxww |grep dss |grep -v grep |awk '{print $2 "/" $NF}' |awk -F/ '{print $1 " : "$NF}' |sed -e "s/.cfg//")" > $TMP
for i in $rcvPorts
do
  pId=$(netstat -antp 2>/dev/null |grep ":${i}" 2>/dev/null |head -n 1 2>/dev/null |awk '{print $(NF)}' 2>/dev/null |grep -oE "[0-9]*" 2>/dev/null)
  cntFile=$(lsof -p $pId |wc -l)
  sed -i "s/\($pId\)\( : [a-z0-9-]*\)/\1\2 : ${i} : ${cntFile}/" $TMP
done
cat $TMP |sort -n -t ':' -k 3 |tee ; \rm -f $TMP
