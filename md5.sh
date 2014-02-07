#!/bin/bash

f=$1
t=133.242.56.158
h=133.242.77.158

if [ -d $f ]; then
  l=$(ls $f)
  for k in $(echo $l)
  do
    ll="$ll ${f}/${k}"
  done
else
  ll=$f
fi

for i in $ll
do
  echo "release $t"
  ssh $t "md5sum $i"
  echo "staging $h"
  md5sum $i
  echo "diff"
  #diff <(ssh $t "cat $i") <(cat $i)
  ssh $t "cat $i" | diff - $i 
done


