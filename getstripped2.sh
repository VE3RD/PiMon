#!/bin/bash
rm /usr/local/etc/stripped2.*
rm /home/pi-star/Scripts/stripped2.*
wget https://raw.githubusercontent.com/EA7KDO/Scripts/master/stripped2.csv /home/pi-star/Scripts/stripped2.csv
cp /home/pi-star/Scripts/stripped2.csv /usr/local/etc/

