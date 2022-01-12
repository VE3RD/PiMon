#!/bin/bash
############################################################
#  This script will automate the process of                #
#  Logging Calls on a Pi-Star Hotpot			   #
#  to assist with Net Logging                              #
#                                                          #
#  VE3RD                              Created 2021/07/05   #
############################################################
set -o errexit 
set -o pipefail 
set -e 
set -o errtrace
set -E -o functrace

ver=2021123001
RED="\e[31m"
GREEN="\e[32m"
LTMAG="\e[95m"
LTGREEN="\e[92m"
LTCYAN="\e[96m"
YELLOW="\e[33m"

ENDCOLOR="\e[0m"



sudo mount -o remount,rw / 
#printf '\e[9;1t'

callstat="" 
callinfo="No Info" 
lastcall2="" 
lastcall1=""
netcont="none"
TG=""
dur=$((0)) 
lfdts="" 
dts="" 
line1=""
nline1=""
calli=""
src="RF"  #"NET"
active=0
sline="                                                                                                                       "
oldline=""
newline=""
server=""
call=""
line2=""
yat=""

err_report() 
{ 
	echo "Error on line $1"
	echo "Last  Call = $call" 
	echo "Last TCall = $tcall" 
	./pimon.sh ReStart
}

trap 'err_report $LINENO' ERR


fnEXIT() {

  echo -en "${BOLD}${WHI}THANK YOU FOR USING pimon by VE3RD!${SGR0}${DEF}"
echo ""
  exit
  
}

trap fnEXIT SIGINT SIGTERM

#M: 2021-12-29 14:55:46.923 YSF, received network data from WB2FLX     to DG-ID 0 at FCS00390

function updatefromqrz(){
. /home/pi-star/.qrz.conf
# get a session key from qrz.com
session_xml=$(curl -s -X GET 'http://xmldata.qrz.com/xml/current/?username='${user}';password='${password}';agent=qrz_sh')

# check for login errors
#e=$(printf %s "$session_xml" | grep -oP "(?<=<Error>).*?(?=</Error>)" ) # only works with GNU grep
e=$(printf %s "$session_xml" | awk -v FS="(<Error>|<\/Error>)" '{print $2}' 2>/dev/null | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n//g')
if [ "$e" != ""  ]
  then
    echo "The following error has occured: $e"
    exit
  fi

# extract session key from response
#session_key=$(printf %s "$session_xml" |grep -oP '(?<=<Key>).*?(?=</Key>)') # only works with GNU grep
session_key=$(printf %s "$session_xml" | awk -v FS="(<Key>|<\/Key>)" '{print $2}' 2>/dev/null | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n//g')

# lookup callsign at qrz.com
lookup_result=$(curl -s -X GET 'http://xmldata.qrz.com/xml/current/?s='${session_key}';callsign='${call}'')

ncall="OK"

# check for login errors
#e=$(printf %s "$lookup_result" | grep -oP "(?<=<Error>).*?(?=</Error>)" ) # only works with GNU grep
e=$(printf %s "$lookup_result" | awk -v FS="(<Error>|<\/Error>)" '{print $2}' 2>/dev/null | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n//g')
if [ "$e" != ""  ]
  then
    	echo "$call  Not Found at QRZ"
	cnt=$((cnt+1))
	nocall="$cnt,$call,NoName,NA,NA.NA,NA,NA" 
	echo "$nocall" >> /usr/local/etc/stripped2.csv
	ncall="NO"
#    exit
#  fi
else
	# grep field values from xml and put them into variables
	#for f in "call" "fname" "name" "addr1" "addr2" "country" "grid" "email" "user" "lotw" "mqsl" "eqsl" "qslmgr"
	for f in "call" "fname" "name" "addr1" "addr2" "state" "country" 
	do

  		#z=$(printf %s "$lookup_result" | grep -oP "(?<=<${f}>).*?(?=</${f}>)" ) # only works with GNU grep
  		z=$(printf %s "$lookup_result" | awk -v FS="(<${f}>|<\/${f}>)" '{print $2}' 2>/dev/null | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n//g')
  		eval "$f='${z}'";
	done

	touch /usr/local/etc/stripped2.csv
	cnt=$((cnt+1))
	newcall=$(echo "$cnt","$call","$fname","$name","$addr2","$state","$country") 
	echo -e "${LTMAG}QRZ: $newcall $cnt added to stripped2.csv ${ENDCOLOR}"
	echo "$newcall" >> /usr/local/etc/stripped2.csv
fi

}


function checkcall(){ 

#	s1checka=$( grep "$call", /usr/local/etc/stripped.csv | head -1 )
#	echo "$s1checka"

if grep -F "$call", /usr/local/etc/stripped.csv 
then  
	echo -en "${LTGREEN}$Time Call:$call Found in Stripped.csv ${ENDCOLOR} \n" 
else
	if grep -F "$call" /usr/local/etc/stripped2.csv 
 	then
		echo -en "${LTCYAN} $Time Call $call Found in Stripped2.csv ${ENDCOLOR} \n"
	else
		echo "$Time Using  QRZ to Locate $call"
		updatefromqrz
	fi 
		   	
fi

}

function GetLastLine(){

        f1=$(ls -tv /var/log/pi-star/MMDVM* | tail -n 1 )
        line1=$(tail -n 1 "$f1" | sed 's/  */ /g')
	newline="$line1"

#	substr="transmission"
	substr="data"

if [ "$oldline" != "$newline" ] &&  [[ "$line1" == *"$substr"* ]]; then
	call=$(echo "$line1" | sed 's/  */ /g' | grep -o 'from.*' | tr "-" " " | tr "/" " " | cut -d " " -f2 )

	clen=$(echo $call | wc -c)
	if [ "$clen" -gt 3 ] && [ "$clen" -lt 7 ]; then
		checkcall
	fi
	oldline="$newline"
fi
}

function StartUp()
{
        f1=$(ls -tv /var/log/pi-star/MMDVM* | tail -n 1 )
        line1=$(tail -n 1 "$f1" | sed 's/  */ /g')
 	lcntt=$(tail -n1 /usr/local/etc/stripped2.csv |  cut -d "," -f1)
        cnt=$((lcntt))
	echo "Records Found in stripped2.csv = $cnt"
	
}

######## Start of Main Program

callstat=""

######### Main Loop Starts Here
#echo "Starting Loop"
StartUp
while true
do 
	cm=0	
 	Time=$(date '+%T')  
	GetLastLine
	sync
#	sleep 5.0
done



