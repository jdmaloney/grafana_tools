#!/bin/bash

action=$1
grouping=$2
tag_or_id=$3

user=  ## Grafana admin user
pass=  ## Passwor for Grafana admin user

if [ "$1" == "-h" ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
	echo "Usage: ./alert_toggle.sh [start/pause] [tag/id] [all/"name of tag"/"alert id"]"
	exit 0
fi


if [ "$grouping" == "tag" ]; then
	tfile1=$(mktemp /tmp/alerts.XXXXXX)
	tfile2=$(mktemp /tmp/alertlist.XXXXXX)
	curl --silent -X GET -u "${user}":"${pass}" -i http://localhost:3000/api/alerts  -H "Content-Type: application/json" > "${tfile1}"
	
	tail -n +10 "${tfile1}" | sed 's/{\"id/{\"\nid/g' | cut -d',' -f 1,6 | cut -d'"' -f 2,5 | cut -d':' -f 2 | sed 's/,\"/\ /g' > "${tfile2}"
	
	
	if [ "${tag_or_id}" == "all" ]; then
		if [ "${action}" == "pause" ]; then
			echo "Pausing All Alerts On $(hostname)"
			response=$(curl -w "%{http_code}\\n" -XPOST -u "${user}":"${pass}" -i http://localhost:3000/api/admin/pause-all-alerts --data-binary @./pause_alerts.json -H "Content-Type: application/json" -s -o /dev/null)
			if [ "${response}" -eq 200 ]; then
				echo "All Alerts Paused Successfully"
			else
				echo "Pausing of Alerts Failed"
			fi
		elif [ "${action}" == "start" ]; then
			echo "Starting All Alerts On $(hostname)"
			response=$(curl -w "%{http_code}\\n" -XPOST -u "${user}":"${pass}" -i http://localhost:3000/api/admin/pause-all-alerts --data-binary @./start_alerts.json -H "Content-Type: application/json" -s -o /dev/null)
			if [ "${response}" -eq 200 ]; then
	        	        echo "All Alerts Started Successfully"
	               	else
	                        echo "Starting of Alerts Failed"
	                fi
		else
			echo Invalid Argument, Valid Arguments are: start, stop
		fi
	else
		if [ "${action}" == "pause" ]; then
			IFS=" " read -r -a alert_ids <<< "$(grep "\[${tag_or_id}\]" "${tfile2}" | awk '{print $1}' | xargs)"
			alert_count=${#alert_ids[@]}
			echo "Pausing All ${alert_count} Alerts on ${tag_or_id}"
			for a in "${alert_ids[@]}"
			do
				echo "${a}"
				response=$(curl -w "%{http_code}\\n" -XPOST -u "${user}":"${pass}" -i http://localhost:3000/api/alerts/"${a}"/pause --data-binary @./pause_alerts.json -H "Content-Type: application/json" -s -o /dev/null)
				if [ "${response}" -eq 200 ]; then
	                                action_success=$((action_success+1))
	                        fi
			done
			echo ${action_success} of "${alert_count}" Paused Successfully
		elif [ "${action}" == "start" ]; then
			IFS=" " read -r -a alert_ids <<< "$(grep "\[${tag_or_id}\]" "${tfile2}" | awk '{print $1}' | xargs)"
			alert_count=${#alert_ids[@]}
			action_success=0
	                echo "Starting All ${alert_count} Alerts on ${tag_or_id}"
	                for a in "${alert_ids[@]}"
	                do
	                       response=$(curl -w "%{http_code}\\n" -XPOST -u "${user}":"${pass}" -i http://localhost:3000/api/alerts/"${a}"/pause --data-binary @./start_alerts.json -H "Content-Type: application/json" -s -o /dev/null)
				if [ "${response}" -eq 200 ]; then
					action_success=$((action_success+1))
				fi
	                done
			echo ${action_success} of "${alert_count}" Started Successfully
		else
			echo Invalid Argument, Valid Arguments are: start, stop
	        fi

	fi

	rm -rf "${tfile1}" "${tfile2}"
elif [ "$grouping" == "id" ]; then
	if [ "${action}" == "pause" ]; then
                        echo "Pausing Alert Number ${tag_or_id}"
                                response=$(curl -w "%{http_code}\\n" -XPOST -u "${user}":"${pass}" -i http://localhost:3000/api/alerts/"${tag_or_id}"/pause --data-binary @./pause_alerts.json -H "Content-Type: application/json" -s -o /dev/null)
                                if [ "${response}" -eq 200 ]; then
					echo "Alert Paused Successfully"
				else
					echo "Alert Failed to Pause"
                                fi
                elif [ "${action}" == "start" ]; then
			echo "Starting Alert Number ${tag_or_id}"
                               response=$(curl -w "%{http_code}\\n" -XPOST -u "${user}":"${pass}" -i http://localhost:3000/api/alerts/"${tag_or_id}"/pause --data-binary @./start_alerts.json -H "Content-Type: application/json" -s -o /dev/null)
                                if [ "${response}" -eq 200 ]; then
					echo "Alert Started Successfully"
				else
					echo "Alert Failed to Start"
                                fi
                else
                        echo Invalid Argument, Valid Arguments are: start, stop
                fi
else
	echo "Invalid option, choose tag or id for second argument"
fi
