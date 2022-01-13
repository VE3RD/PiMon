#!/bin/bash
if [ ! -f /home/pi-star/.qrz.conf ]; then
  cp .qrz.conf  /home/pi-star/
fi
cp stripped2.csv /usr/local/bin/
nano /home/pi-star/.qrz.conf
