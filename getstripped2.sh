#!/bin/bash
rm /home/pi-star/PiMon/stripped2.cs*
wget https://raw.githubusercontent.com/VE3RD/PiMon/main/stripped2.csv /home/pi-star/PiMon/stripped2.csv
cp /home/pi-star/PiMon/stripped2.csv /usr/local/etc/

