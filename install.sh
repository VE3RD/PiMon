#!/bin/bash
#########################################################
#                                             		#
#  install pimon					#
#                                         		#
#  Parameter $1 = 'New' will delete stripped2.csv  	#
#  and install from github                        	#
#                                              		#
#                                                       #
#  VE3RD                                    2022-01-13  #
#########################################################
set -o errexit


sudo mount -o remount,rw /

if [ "$1" = "New" ]; then
  rm /usr/local/bin/stripped2.csv
fi

if [ ! -f /home/pi-star/.qrz.conf ]; then
  cp ./.qrz.conf  /home/pi-star/
fi
if [ ! -f /usr/local/etc/stripped2.csv ]; then
	cp ./stripped2.csv /usr/local/bin/
fi
nano /home/pi-star/.qrz.conf
