#!/bin/bash
echo "********MacOpen Tool(For Shell)********"
echo "正在切换至dhcp..."
cp /etc/config/network_dhcp /etc/config/network
/etc/init.d/network reload  # reload network service
sleep 1
##Server GXNU:202.193.160.123  GUET:172.16.1.1##
server="172.16.1.1"
echo "Server:" $server
mac=$(ifconfig eth1 | grep "HWaddr" | awk -F" " '{print $5}')
echo "MAC Address:" $mac
ipadd=$(ifconfig eth1 | grep "inet addr" | awk '{ print $2}' | awk -F: '{print $2}')
echo "Local IP Address:" $ipadd
isp=02  # 01: China Unicom, 02: China Telecom, 03: China Mobile
echo "ISP Vendor Signature:" $isp
echo "========================================="
#########################
#Mod Function
function mod(){
  val1=$1
  val2=$2
  t1=0
  result=0
  let "t1 = val1 / val2"
  if [ $val1 -lt $((0)) ]; then
    let "t1=t1-1"
  fi
  let "result = val1 - t1 * val2"
  echo $result
}
#Int overflow function
function int_overflow(){
maxint=2147483647
val=$1
if [ $val -lt $((0-$maxint-1)) ] || [ $val -gt $((maxint)) ] ;
then
  val1=0
  val2=0
  let  "val1 = val + (maxint + 1) "
  let  "val2 = (2 * (maxint + 1)) "
  let  "val = $(mod $val1 $val2) - maxint - 1"
fi
echo $val
}
function c2ascll(){
  printf "%d" "'$1"
}
function dec2hex(){
  if [ $1 -lt 10 ]; then
    echo $1
  else
    printf "%x" $1
  fi
}
localInfo=(00 00 00 00 00 00
00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00
00 00 00 00 00 00)
ispKey=1315423911  #1315423911 is 0x4e67c6a7
localInfo[0]=97  # Uncleared
nmac=${#mac}
nInfo=${#localInfo[@]}

ipaddress=(00 00 00 00)
fff=(${ipadd//./ })
for((i=0;i<4;i++)); do
  ipaddress[i]=${fff[i]}
done
for((i=0;i<4;i++)); do
  localInfo[i+30]=${ipaddress[i]}  # Fill with IP Address
done

for((i=0;i<nmac;i++)); do
  localInfo[i+34]=$(c2ascll ${mac:$i:1})  # Fill with MAC Address
done
localInfo[54]=$isp  # ISP
localInfo[55]=0  # Request to PPPoE

# Get Key Numbers
ESI=0
EBX=0
ECX=0
ESI2=0
ECX=$ispKey
z1=0
for((i=0;i<$nInfo-4;i++))
do
        ESI=$ECX
  let "ESI=ECX<<5"
  ESI=$(int_overflow $ESI)
        if [ $ECX -gt 0 ]
        then
                EBX=$ECX
    let "EBX=ECX>>2"
        else
                EBX=$ECX
    let "EBX=ECX>>2"
    let "EBX=EBX|0xC0000000"
        fi
  let "ESI=ESI+localInfo[i]"
  z1=0
  let "z1=EBX+ESI"
  let "EBX=$(int_overflow $z1)"
  let "ECX=ECX^EBX"
done
let "ECX=ECX&0x7FFFFFFF"

for((i=0;i<4;i++))
do
    let "keypart=((ECX>>(i*8))&0x000000FF)"
    localInfo[$nInfo-4+i]=$keypart  # Fill with Key Numbers
done
data=''
for((i=0;i<$nInfo;i++))
do
z=$(dec2hex ${localInfo[i]})  # Cover Dec to Hex
if [ ${#z} -lt 2 ]; then
  z="0"$z
fi
data=$data"\\x"$z
done
echo $data
echo -n -e ${data}| socat - udp4-datagram:$server:20015  #Send it!
echo
echo '正在进行 PPPoE 拨号...'
cp /etc/config/network_pppoe /etc/config/network
/etc/init.d/network reload  # Reload network service
sleep 1
echo
echo "OK...All done!!"