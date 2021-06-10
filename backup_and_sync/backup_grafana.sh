#!/bin/bash

## Fill in destination host/path variables and db info if necessary
source ./config

## Get Grafana backing DB type
db_type=$(grep "^type = " /etc/grafana/grafana.ini | cut -d' '- f 3)

if [ "${db_type}" == "sqlite3" ]; then
	systemctl stop grafana-server
	data_path=$(grep "data = " /etc/grafana/grafana.ini | cut -d' ' -f 3)
	scp ${data_path}/grafana.db ${destination_host}:/${destination_path}/
	systemctl start grafana-server
elif [ "${db_type}" == "mysql" ]; then
	backup_file_name=grafana_backup_$(date +$Y_%m_%d_%H_%M_%S)
	mysqldump -u ${db_user} -p${db_password} ${db} > /tmp/${backup_file_name}
	scp /tmp/${backup_file_name} ${destination_host}:/${destination_path}/
elif [ "${db_type}" == "postgres" ]; then
	echo "Postgres backend not currently supported"
	exit 1
else
	echo "Invalid/No Database type found; please inspect you grafana.ini file"
	exit 1
fi
