#!/bin/bash
## config area
server="172.16.1.1"  # GUET: 172.16.1.1; GXNU: 202.193.160.123
isp=02               # 01: China Unicom, 02: China Telecom, 03: China Mobile
username=            # your PPPoE username
password=            # your PPPoE password


echo "********MacOpen Tool(For Shell)********"

function status_check() {
  ifconfig | grep pppoe > /dev/null
  if [[ $? -eq 0 ]]; then
    echo "Already dialed"
    exit 0
  fi
}

function help() {
  echo 'dial.sh [Switch]'
  echo 'Usage: dial PPPoE in GUET or GXNU'
  echo 'Switch:'
  echo '          -h or --help: print this page'
  echo '          -f or --force: force dial, ignore status check'
  exit 0
}

function ping_test() {
  ping -w 5 ${ADDRESS}
  return $?
}

if [[ $1 = "-h" ]] || [[ $1 = "--help" ]]; then
  help
elif [[ $1 = "-f" ]] || [[ $1 = "--force" ]]; then
  :
elif [[ -z $1 ]]; then
  status_check
fi


echo "Switching to DHCP"
uci set network.wan.proto='dhcp'
uci delete network.wan.username
uci delete network.wan.password
uci commit network
/etc/init.d/network reload
sleep 10  # wait to get ip addr from DHCP server

echo "Server:" $server
mac=$(ifconfig eth1 | grep "HWaddr" | awk -F" " '{print $5}')
echo "MAC Address:" $mac
ipadd=$(ifconfig eth1 | grep "inet addr" | awk '{ print $2}' | awk -F: '{print $2}')
echo "Local IP Address:" $ipadd
echo "ISP Vendor Signature:" $isp
echo "username:" $username
echo "password:" $password
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
00 00 00 00 00 00) #create array
ispKey=1315423911  #1315423911 is magic number 0x4e67c6a7, see also page 19 in https://github.com/xuzhipengnt/ipclient_gxnu/blob/master/doc/%E5%8E%9F%E7%90%86%E6%96%87%E6%A1%A3.pdf
localInfo[0]=97
nmac=${#mac}
nInfo=${#localInfo[@]}

ipaddress=(00 00 00 00)
fff=(${ipadd//./ })
for((i=0;i<4;i++)); do
  ipaddress[i]=${fff[i]}
done
for((i=0;i<4;i++)); do
  localInfo[i+30]=${ipaddress[i]}  #fill package with IP Address
done

for((i=0;i<nmac;i++)); do
  localInfo[i+34]=$(c2ascll ${mac:$i:1})  #fill package with MAC Address
done
localInfo[54]=$isp  #ISP

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
    localInfo[$nInfo-4+i]=$keypart  #Key Numbers
done
data=''
for((i=0;i<$nInfo;i++))
do
z=$(dec2hex ${localInfo[i]})  #Cover Dec to Hex
if [ ${#z} -lt 2 ]; then
  z="0"$z
fi
data=$data"\\x"$z
done
echo $data
echo -n -e ${data}| socat - udp4-datagram:$server:20015  #Send it!
echo
echo 'Dialing PPPoE...'
sleep 5
uci set network.wan.proto='pppoe'
uci set network.wan.username="$username"
uci set network.wan.password="$password"
uci commit network
/etc/init.d/network reload
sleep 10
ping_test
[[ $? != 0 ]] && exit 1
echo
echo "OK...All done!!"
