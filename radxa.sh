#!/bin/bash
############################################################
#  This script will automate the process of                #
#  Logging Calls on a RADXA Zero Hotpot			   #
#  to assist with Net Logging                              #
#                                                          #
#  VE3RD                              Created 2022/06/23   #
############################################################
#set -o errexit 
#set -o pipefail 
set -e
#set -e 
#set -o errtrace
#set -E -o functrace

ver=2022062301

sudo mount -o remount,rw / 
#printf '\e[9;1t'

callstat="" 
callinfo="No Info" 
lastcall2="" 
lastcall1=""
netcont="none"
stat=""
dt1=""
P1="$1"
if [ ! -z "$P1" ]; then
	netcont=$(echo "$P1" | tr '[:lower:]' '[:upper:]')
fi

P2="$2"
if [ "$P2" ]; then
#	P2S=${P2^^} 
#	stat=${P2^^}
	stat=$(echo "$P2" | tr '[:lower:]' '[:upper:]')
fi
P3="$3"
if [ "$P3" ]; then
	P3S=${P3^^} 
fi

TG="NA"
#echo "$netcont"   "$stat" 
dur=$((0)) 
pl=""
ber=""
cm=0 
lcm=0 
ber=0 
netcontdone=0 
nodupes=0 
rf=0 
clen=$((0))
lfdts="" 
dts="" 
nline1=""
calli=""
src="RF"  #"NET"
active=0
sline="                                                                                                                       "
oldline=""
newline=""
pmode=""
mode=""
server=""
call=""
line2=""
yat=""
keybd="no"
amode="no"
stripped=0


fnEXIT() {

  echo -e "${BOLD}${WHI}THANK YOU FOR USING RADXA Dashboard Monitor by VE3RD!${SGR0}${DEF}"
echo ""
  exit
  
}

trap fnEXIT SIGINT SIGTERM



function header(){
	clear
	set -e sudo mount -o remount,rw / 
	echo ""
	echo "RADXA Dashboard Monitor Program by VE3RD Version $ver"
#	echo ""
	echo "Dates and Times Shown are Local to your hotspot"
#	echo ""
	echo "0, Log Started $dates" | tee /home/pi-star/radxalog.log > /dev/null
#	echo "0, Net Log Started $dates" > /home/pi-star/radxalog.log
	echo ""
}

function getserver(){
#	server=$(grep "$tg" /usr/local/etc/RADXA*.txt |tail -n1 | tr -s '\t' ' ' | cut -d " " -f2)
	address=$(sudo sed -n '/^[ \t]*\[DMR Network\]/,/\[/s/^[ \t]*Address[ \t]*=[ \t]*//p' /etc/mmdvmhost)
server=$(grep $address /usr/local/etc/DMR_Hosts.txt | head -1 | cut -f1)
       if [ -z "$server" ]; then
		server="N/A"
	fi
}

function getuserinfo(){
stripped=0
	if [ ! -z  "$call" ]; then
 		lines=$(sed -n '/'",$call"',/p' /usr/local/etc/stripped.csv | head -n 1)	
		
		if [ "$lines"  ]; then
			stripped=2
		fi
		line=$(echo "$lines" | head -n1)

		if [ ! -z line ] || [ stripped == 0 ]; then
			name=$(echo "$line" | cut -d "," -f 3 | cut -d " " -f 1)
#			name=$(echo "$line" | cut -d "," -f 3 )
			city=$(echo "$line"| cut -d "," -f 5)
			state=$(echo "$line" | cut -d "," -f 6)
			country=$(echo "$line" | cut -d "," -f 7)
		else
			callinfo="No Info"
			name="NA"
			city="NA"
			state="NA"
			country="NA"
		fi
fi
sudo mount -o remount,rw / 

}



function ProcessNewCall(){ 

RED="\e[31m"
GREEN="\e[32m"
LTMAG="\e[95m"
LTGREEN="\e[92m"
LTCYAN="\e[96m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"


#echo "Processing Call:$call Mode:$pmode"

sudo mount -o remount,rw / 

	getuserinfo 
	getserver 

    case "$mode" in 
        1R )
printf "${YELLOW}$mode %s %-8s %-6s %s, %s, %s, %s, %s  %s ${ENDCOLOR} \n" "$dt1" "$Time" "$call" "$name" "$city" "$state" "$country" "$server" "$tg"	
;;
        2R ) 
printf "${LTGREEN}$mode %s %-8s %-6s %s, %s, %s, %s, %s  %s %s %s ${ENDCOLOR} \n" "$dt1" "$Time" "$call" "$name" "$city" "$state" "$country" "$server" "$tg" "Dur:$dur secs " "BER:$ber"	
;;
        1N )  
printf "${LTMAG}$mode %s %-8s %-6s %s, %s, %s, %s, %s  %s ${ENDCOLOR} \n" "$dt1" "$Time" "$call" "$name" "$city" "$state" "$country" "$server" "$tg"	
;;
        2N )  
printf "${LTCYAN}$mode %s %-8s %-6s %s, %s, %s, %s, %s  %s %s %s %s ${ENDCOLOR} \n" "$dt1" "$Time" "$call" "$name" "$city" "$state" "$country" "$server" "$tg" "DUR:$dur" "BER:$ber" "PL:$pl"

;;
esac


	sudo mount -o remount,rw / 
	printf "${ENDCOLOR}"
			

}
################################

function GetLastLine(){

        f1=$(ls -tv /var/log/pi-star/MMDVM* | tail -n 1 )
        line1=$(tail -n 1 "$f1" | sed 's/  */ /g')
        newline="$line1"
#       substr="transmission"
        substr="data"


	if [ "$oldline" != "$newline" ]; then

# 1R  M: 2022-06-23 18:45:09.636 DMR Slot 2, received RF voice header from VE3RD to TG 14031665
# 2R M: 2022-06-23 18:45:10.346 DMR Slot 2, received RF end of voice transmission from VE3RD to TG 14031665, 0.7 seconds, BER: 0.5%, RSSI: -47/-47/$
# 1N M: 2022-06-23 18:46:24.899 DMR Slot 2, received network voice header from WW4MO to TG 14031665
# 2N M: 2022-06-23 18:46:25.610 DMR Slot 2, received network end of voice transmission from WW4MO to TG 14031665, 0.8 seconds, 0% packet loss, BER:$
#M: 20


if [[ $line1 =~ "RF voice header" ]]; then
   mode="1R"
fi
if [[ $line1 =~ "RF end of" ]]; then
   mode="2R"
   dur=$(echo "$line1" | sed 's/  */ /g' | grep -o 'from.*' | cut -d " " -f6 )
   ber=$(echo "$line1" | sed 's/  */ /g' | grep -o 'from.*' | cut -d " " -f9 )
  
fi
if [[ $line1 =~ "network voice header" ]]; then
   mode="1N"
fi
if [[ $line1 =~ "network end of" ]]; then
   mode="2N"
   dur=$(echo "$line1" | sed 's/  */ /g' | grep -o 'from.*' | cut -d " " -f6 )
   ber=$(echo "$line1" | sed 's/  */ /g' | grep -o 'from.*' | cut -d " " -f12 )
   pl=$(echo "$line1" | sed 's/  */ /g' | grep -o 'from.*' | cut -d " " -f8 )

fi
   
tg=$(echo "$line1" | sed 's/  */ /g' | grep -o 'from.*' | cut -d " " -f5 | tr -d ',')

        	call=$(echo "$line1" | sed 's/  */ /g' | grep -o 'from.*' | cut -d " " -f2 )
		ok=false
		newline="$line1"
#		call=$(echo "$line1" | cut -d " " -f6)
#		tg=$(echo "$line1" | cut -d " " -f11)
#        	tg=$(echo "$line1" | sed 's/  */ /g' | grep -o 'from.*' | cut -d " " -f5 )
                dt=$(date --rfc-3339=ns)

		ProcessNewCall
		oldline="$newline"
	fi


}


function StartUp()
{
echo "Starting the RADXA Dashboard Monitor"
        f1=$(ls -tv /var/log/pi-star/MMDVM* | tail -n 1 )
#        line1=$(tail -n 1 "$f1" | tr -s \ |  sed -n -e 's/^.*to //p')
#	nline1=$(tail -n 1 "$f1" | tr -s \ |  sed 's/ *$//g' | sed 's/%//g' | sed 's/,//g' )   #sed 's/h//g'
	nline1=$(tail -n 1 "$f1" | tr -s \ )

        newline="$nline1"
	oldline="$nline1"

if [ "$netcont" != "ReStart" ]; then

	if [ "$netcont" == "HELP" ]; then
		help
		exit
	fi

	if [ "$netcont" == "NEW" ] || [ "$stat" == "NEW" ]; then
		## Delete and start a new data file starting with date line
		dates=$(date '+%A %Y-%m-%d %T')
        	header 
		
	elif [ "$netcont" == "OLD" ] || [ "$stat" == "OLD" ]; then
		## Delete and start a new data file starting with date line
		dates=$(date '+%A %Y-%m-%d %T')

	elif [ "$netcont" != "NEW" ] && [ "$stat" == "NEW" ]; then
		call="$netcont"
		processnewcall

	fi

fi
}

######## Start of Main Program
###LoopKeys

StartUp

#getnewcall
callstat=""

######### Main Loop Starts Here
#echo "Starting Loop"

while true
do 
kbd=false
sudo mount -o remount,rw / 

	sync
#	sleep 1.0

#	while read -t0.5 -n1 k  
#  	do 
#	    	if [ "$k" == "s" ]; then
#        		searchcall
#    		else
#			kbd=true
#			getinput
#		fi
#	done

	cm=0	
        dt1=$(date '+%m-%d')

 	Time=$(date '+%T') 
	GetLastLine 
done

	




done
echo "No Longer True"
