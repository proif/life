#!/bin/bash

TMP=$(mktemp) ; rcvPorts="8085 8086 8087"
echo "$(ps auxww |grep dss |grep -v grep |awk '{print $2 "/" $NF}' |awk -F/ '{print $1 " : "$NF}' |sed -e "s/.cfg//")" > $TMP
for i in $rcvPorts
do
  pId=$(netstat -antp |grep :${i} |head -n 1 |awk '{print $(NF)}' |grep -o [0-9]*)
  sed -i "s/\($pId\)\( : [a-z0-9-]*\)/\1\2 : ${i}/" $TMP
done
cat $TMP ; \rm -f $TMP
