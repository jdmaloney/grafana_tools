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

rsync -avP img/fav32.png /usr/share/grafana/public/img/
rsync -avP img/grafana_com_auth_icon.svg /usr/share/grafana/public/img/
rsync -avP img/mstile-150x150.png /usr/share/grafana/public/img/

login_light=$(ls /usr/share/grafana/public/build/static/img/ | grep g8_login_light)
login_dark=$(ls /usr/share/grafana/public/build/static/img/ | grep g8_login_dark)
logo=$(ls /usr/share/grafana/public/build/static/img/ | grep grafana_icon)

rsync -avP img_new/login_light.svg /usr/share/grafana/public/build/static/img/${login_light}
rsync -avP img_new/login_dark.svg /usr/share/grafana/public/build/static/img/${login_dark}
rsync -avP img_new/grafana_icon.svg /usr/share/grafana/public/build/static/img/${logo}


cd /usr/share/grafana/public/build/

files=($(grep -l "Welcome to Grafana" *.js | grep -v LICENSE | grep -v map | grep -v backup | grep -v explore))

for f in ${files[@]}
do
	cat ${f} | sed "s/LoginTitle\=\"Welcome\ to\ Grafana\"/LoginTitle\=\"${title}\"/" > temp.out
	mv temp.out ${f}
	cat ${f} | sed "s/GetLoginSubTitle\=()=>null/GetLoginSubTitle\=()=>\"${subtitle}\"/" > temp.out
	mv temp.out ${f}
done

systemctl restart grafana-server
