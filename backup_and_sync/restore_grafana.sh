#!/bin/bash

## Source file from argument
source_file=$1

## Fill in destination_host and destination_path in config file; as well as db info if applicable
source ./config

## Get Grafana backing DB type
db_type=$(grep "^type = " /etc/grafana/grafana.ini | cut -d' '- f 3)

if [ "${db_type}" == "sqlite3" ]; then
	systemctl stop grafana-server
	data_path=$(grep "data = " /etc/grafana/grafana.ini | cut -d' ' -f 3)
	scp ${source_file} ${data_path}/grafana.db
	systemctl start grafana-server
elif [ "${db_type}" == "mysql" ]; then
	systemctl stop grafana-server
	mysql -u ${db_user} -p${db_password} ${db} < ${source_file}
	systemctl start grafana-server
elif [ "${db_type}" == "postgres" ]; then
	echo "Postgres backend not currently supported"
	exit 1
else
	echo "Invalid/No Database type found; please inspect you grafana.ini file"
	exit 1
fi
