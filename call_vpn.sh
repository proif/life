#!/bin/bash
#####                                            #####
##### Cloud VPN Server Call Amplidate VPN Script #####
#####                                            #####

####Variable######
nameHost=$(hostname)
localHostSuffix=$(echo $nameHost |awk -F '-' '{print $NF}')
pathSelf=/usr/local/bin
pathLog=/var/log/vpn_call.log
flagDebug=0 #debug flag

#####Function#####
. ${pathSelf}/functions

function chk_ping(){
  logFile=$pathLog
  pingTarget="$1"
  pingFailIps=

  for i in $pingTarget
  do
    ping -c 3 -W 1 $i > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      pingFailIps="${pingFailIps} ${i}"
    fi
  done

  if [ "X${pingFailIps}" = X ]; then
    return 0
  else
    echo "##### ping failed : ${pingFailIps}" |tee -a $logFile
    return 1
  fi
}

function chk_service(){
  logFile=$pathLog
  #xl2tpd (pid  10019) is running...

  #IPsec running - pluto pid: 17317 pluto pid 17317 1 tunnels up some eroutes exist
  #IPsec running  - pluto pid: 10130 pluto pid 10130 No tunnels up

  #keepalived (pid  1432) is running...

  #IPsec stopped

  stateService=$(service $1 status)
  if [ $? -ne 0 ]; then
    if echo $stateService |grep -qiE "stopped" ; then
      service $1 start || echo "##### Start $1 Service Failed" |tee -a $logFile; exit 1
      echo "##### Start $1 Service" |tee -a $logFile
    fi
  else
    echo "$1 service running..." |tee -a $logFile
  fi
}

function chk_dev(){
  ##### network interface #####
  nameChkDev=$1
  logFile=$pathLog
  retryCnt=0
  tmpDev=$(ifconfig |grep $1 |awk '{print $1}')

  while [ "X${tmpDev}" = "X" ]
  do
    if [ $retryCnt -gt 5 ]; then
      echo "##### ${1} interface nothing" |tee -a $logFile
      #echo "######## ${0}   Script Ended   ########" >> $logFile
      exit 1
    else
      sleep 3
      tmpDev=$(ifconfig |grep $1 |awk '{print $1}')
      retryCnt=$(expr $retryCnt + 1)
    fi
  done

  echo "##### $nameChkDev interface check OK" |tee -a $logFile
}

function chk_ip(){
  ##### local vip check #####
  ADDR=$1
  CNT=0
  logFile=$pathLog

  while [ "X${ADDR}" = "X" ]
  do
    if [ $CNT -gt 5 ]; then
      echo "$ADDR setting nothing" |tee -a $logFile
      echo "##### ${0} Script Failed" |tee -a $logFile
      exit 1
    else
      sleep 2
      ADDR=$(ip addr show | grep $ADDR)
      CNT=$(expr $CNT + 1)
    fi
  done

  echo "##### ${ADDR} setting OK" |tee -a $logFile
}

function chk_line(){
  logFile=$pathLog
  chk_service keepalived
  chk_ip ${addrLocalVip}
  case $nameNw in
  *_ipenc)
    echo "##### check Connection line VPN Cloud <> ipenc #####" >> $logFile
  ;;
  *_ampli)
    echo "##### check Connection line VPN Cloud <> Amplidate #####" >> $logFile
    eval $XL2TP_CMD
    chk_service xl2tpd
    eval $PPP_CMD
    chk_dev ppp
    chk_ip ${addrLocalTunIp}
    eval $IPSEC_CMD
    chk_service ipsec
  ;;
  esac
}

function conn_tunnel(){
  echo "##### Start connection setting"
  eval $CON_CMD || (echo "      Connection Failed!!!" |tee -a $logFile; exit 1)
}

#function up_ppp(){
#  echo "##### start ppp device . . . #####" >> $logFile
#  eval $PPP_CMD || (echo "      PPP Device Setting Failed!!!" >> $logFile; exit 1)
#}

function set_route(){
  echo "##### setting static route . . ." |tee -a $logFile
  eval $ROUTE_CMD >> $logFile
}

function chk_tunnel(){
  case $nameNW in
  *_ampli)
    #chk_ipsec_tunnel
    echo "##### check ipsec status" |tee -a $logFile
    ipsec auto --status |grep -q "interface ppp0/ppp0"
    if [ $? -eq 0 ]; then
      echo "ipsec tunnel was built definitely. " |tee -a $logFile
    else
      echo "ipsec tunnel is in state that it is not right" |tee -a $logFile
    fi
  ;;
  *_ipenc)
    #chk_ipip_tunnel(){
    ech "##### check ipip tunnel" |tee -a $LogFile
    ip tunnel list |grep "utn0 ip/ip  remote ${addrIpenc}  local ${addrLocalVip}"
    if [ $? -eq 0 ];then
      echo "ipip tunnel was built definitely." |tee -a $logFile
    else
      echo "ipip tunnel is in state that it is not right" |tee -a $logFile
    fi
  ;;
  esac
}

########Function###############

get_nw
set_nw $nameNw
chk_ping "${addrRealIpList}"

if echo $nameNw | grep -q ampli ; then
  PPP_CMD="echo \"c \${nameXl2tpLac}\" > /var/run/xl2tpd/l2tp-control"
  CON_CMD="ipsec auto --down \${nameIpsecConn} && ipsec auto --up \${nameIpsecConn}"
  for i in ${addrRealIpList};
  do
    if echo ${pingFailIps} |grep -q ${i}; then
      :
    else
      ROUTE_CMD="${ROUTE_CMD} ssh  $i \"ip route add ${backNw} dev ppp0\" ; "
      IPSEC_CMD="${IPSEC_CMD} ssh  $i \"service ipsec restart\" ; "
      XL2TP_CMD="${XL2TP_CMD} ssh  $i \"service xl2tpd restart\" ; "
    fi
  done
  ROUTE_CMD="${ROUTE_CMD} ip route add ${faceNw} dev ppp0"
  IPSEC_CMD="${IPSEC_CMD} service ipsec restart"
  XL2TP_CMD="${XL2TP_CMD} service xl2tpd restart"
elif echo $nameNw | grep -q ipenc ; then
  PPP_CMD=
  CON_CMD="ip tunnel add tun0 mode ipip remote ${addrIpenc} local ${addrLocalVip} && \
ifconfig tun0 ${addrLocalTunIp} netmask 255.255.255.252 pointopoint ${addrFaceTunnel} && \
ifconfig tun0 mtu 1480 up && \
ip link set tun0 up"
  ROUTE_CMD="ip route add 10.0.0.0/8 dev tun0 && \
ip route add 172.16.0.0/12 dev tun0 && \
ip route add 192.168.0.0/16 dev tun0 && \
ip route add ${addrSakuraNw} dev tun0"
elif echo $nameNw | grep -q unknown ; then
  echo "unknown network" >> $pathLog
  exit 1
fi

while getopts d OPT
do
  case $OPT in
  d)
    flagDebug=1
  ;;
  esac
done

if [ $flagDebug -eq 1 ]; then
  ############ debug ###################
  echo "addrNwAddrOct: " $addrNwAddrOct
  echo "addrNwAddrOct_4: " $addrNwAddrOct_4
  echo "nameNw: " $nameNw
  echo "addrLocalIp: " $addrLocalIp
  echo "nameHost: " $nameHost
  echo "addrLocalVip: " $addrLocalVip
  echo "addrLocalTunIp: " $addrLocalTunIp
  echo "addrFaceVip: " $addrFaceVip
  echo "addrFaceTunnel: " $addrFaceTunnel
  echo "faceNw: " $faceNw
  echo "backNw: " $backNw
  echo "addrZabbixTarget: " $addrZabbixTarget
  echo "nameIpsecConn: " $nameIpsecConn
  echo "nameXl2tpLac:" $nameXl2tpLac
  echo "IPSEC_CMD:" $IPSEC_CMD
  echo "XL2TP_CMD:" $XL2TP_CMD
  echo "ROUTE_CMD: " $ROUTE_CMD
  echo "CON_CMD: " $CON_CMD
  ######################################
fi

echo "##### $(date) Start $0 Script #####" |tee -a $pathLog

if [ $flagDebug -eq 0 ]; then
  chk_line
  conn_tunnel
  chk_tunnel
  set_route
  echo "##### VPN Connected" |tee -a $logFile
elif [ $flagDebug -eq 1 ]; then
  echo "##### Debug mode #####" |tee -a $pathLog
  echo $tmpDev
fi

if chk_ping "${addrFaceVip} ${addrLocalVip}" ; then
  echo "##### ping check ${addrFaceVip} ${addrLocalVip} OK" |tee -a $pathLog
else
  echo "##### ping failed ${pingFailIps}" |tee -a $pathLog
  exit 1
fi

cat << EOF >> $pathLog

############################
##### Script Completed #####
############################
EOF
exit 0 
