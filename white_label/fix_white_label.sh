#!/bin/bash

##
## Set what you want your title and the subtitle to be
## keep the double quotes around them
##
source ./config

##
## Images in this repo are an example you'll want to use
## your own images, copy resolutions and file formats;
## note that the resolution of the login background images
## can vary, but make sure they are at least 1280 x 720
rsync -avP img/* /usr/share/grafana/public/img/

cd /usr/share/grafana/public/build/

files=($(ls | grep "^app." | grep -v LICENSE | grep -v map))

for f in ${files[@]}
do
	cat ${f} | sed "s/s.LoginTitle=\"Welcome to Grafana\"/s.LoginTitle=\"${title}\"/" > temp.out
	mv temp.out ${f}
	cat ${f} | sed "s/AppTitle=\"Grafana\"/AppTitle=\"${title}\"/g" > temp.out
	mv temp.out ${f}
	cat ${f} | sed "s/SubTitle=()=>null/SubTitle=()=>\"${subtitle}\"/" > temp.out
	mv temp.out ${f}
done

systemctl restart grafana-server
