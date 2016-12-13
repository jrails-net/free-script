#!/bin/bash

echo 'loading monitor.sh'
source ./function.sh

out_file=$1

echo "Container,Interface,TX,RX,Size,Time" > $out_file
while true;
do
  names=$(docker ps --format '{{.Names}}')
  time=$(date +"%Y%m%d%H%M%S")
  for name in $names
  do
    record=""
    key="" 
    interface_name=$(ovs-vsctl --data=bare --no-heading --columns=name find interface external_ids:container_id=$name)
    if [ "$interface_name" != "" ]; then 
      key="${name},${interface_name}"
      tx_bytes=$(ovs-vsctl list interface $interface_name | grep -Po 'tx_bytes=\K[0-9]+')
      rx_bytes=$(ovs-vsctl list interface $interface_name | grep -Po 'rx_bytes=\K[0-9]+')
    else
      interface_name="none"  
      key="${name},${interface_name}"
      tx_bytes=0
      rx_bytes=0
    fi
    container_size_str=$(docker ps -a -s --format '{{.Size}}' --filter name=${name} | grep -o '^[0-9]\+.[0-9]\+ \(TB\|GB\|MB\|kB\|B\)')
    container_size=0
    if [[ $container_size_str =~ TB ]]; then
      container_size=$(echo $(echo ${container_size_str} | sed 's/TB/*1024*1024*1024*1024/g') | bc)
    elif [[ $container_size_str =~ GB ]]; then
      container_size=$(echo $(echo ${container_size_str} | sed 's/GB/*1024*1024*1024/g') | bc)
    elif [[ $container_size_str =~ MB ]]; then
      container_size=$(echo $(echo ${container_size_str} | sed 's/MB/*1024*1024/g') | bc)
    elif [[ $container_size_str =~ kB ]]; then
      container_size=$(echo $(echo ${container_size_str} | sed 's/kB/*1024/g') | bc)
    elif [[ $container_size_str =~ B ]]; then
      container_size=$(echo $(echo ${container_size_str} | sed 's/B/*1/g') | bc)
    fi
    record="${key},${tx_bytes:=-1},${rx_bytes:=-1},${container_size:=0},${time}" 
    if grep -Fq "$key" $out_file
    then
      sed -i "s@$key.*@$record@g" $out_file
    else
      echo $record >> $out_file
    fi
  done
  sleep 10 
done
