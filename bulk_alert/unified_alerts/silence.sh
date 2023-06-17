#!/bin/bash

source ./config

if [ -z "${1}" ]; then
	echo "Please type your name"
	read var_name

	echo "Please a comment about this silence"
	read var_comment

	echo "Please Enter the label to filter with"
	read var_type

	echo "Please Enter the filter value"
	read var_value

	echo "Enter start time of silence, example format: 2023-06-16 14:00:00"
	read var_start_raw

	echo "Enter end time of silence, example format: 2023-06-16 15:00:00"
	read var_end_raw

elif [ "${1}" == "-h" ]; then
	echo "Example: ./silence.sh \"Your Name\" \"Silence Comment\" label value \"2023-06-17 14:00:00\" \"2023-06-18 14:00:00\""
	exit 0
else
	var_name=$1
	var_comment=$2
	var_type=$3
	if [ "${var_type}" == "system" ]; then
		var_type="System"
	fi
	var_value=$4
	var_start_raw=$5
	var_end_raw=$6
fi

zone=$(date +%Z)
var_start=$(TZ=UTC date -d "${var_start_raw} ${zone}" +"%Y-%m-%dT%H:%M:%S.000Z")
var_end=$(TZ=UTC date -d "${var_end_raw} ${zone}" +"%Y-%m-%dT%H:%M:%S.000Z")

cp ./silence.json.template ./silence.json
sed -i "s/var_comment/${var_comment}/" ./silence.json
sed -i "s/var_name/${var_name}/" ./silence.json
sed -i "s/var_type/${var_type}/" ./silence.json
sed -i "s/var_value/${var_value}/" ./silence.json
sed -i "s/var_start/${var_start}/" ./silence.json
sed -i "s/var_end/${var_end}/" ./silence.json

response=$(curl -w "%{http_code}\\n" -XPOST -u "${user}":"${pass}" -i http://localhost:3000/api/alertmanager/grafana/api/v2/silences --data-binary @./silence.json  -H "Content-Type: application/json" -s -o /dev/null)
if [ "${response}" -eq 202 ]; then
	echo "**Silence Created Successfully**"
else
	echo "!!Failed to Create Silence!!"
fi

rm -rf ./silence.json
