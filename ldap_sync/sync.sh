#!/bin/bash

if [ -z $1 ]; then
	set -- $1 "regular"
fi

tfile=$(mktemp /tmp/grafana.XXXXXX)

## Fill in appropriate path to directory containing script & the Grafana Admin Password & the array of groups in config file
source ./config

## Loop over groups; make sure still in LDAP; if not delete respective team in Grafana
for g in ${groups[@]}
do
	if [ $1 == "--debug" ]; then
		echo "Validating Group ${g} is still in LDAP"
	fi
	if [ -z "$(/usr/bin/ldapsearch -x "(cn=${g})" | grep uniqueMember)" ]; then
		## Remove Team
		if [ $1 == "--debug" ]; then
			echo "Group ${g} No Longer in LDAP"
		fi
		id=$(curl -w "%{http_code}\\n" -u admin:${admin_password} -i http://localhost:3000/api/teams/search?name="${g}" -H "Content-Type: application/json" -s | grep "totalCount" | cut -d':' -f 4 | cut -d',' -f 1)
		if [ -n "${id}" ]; then
			curl -w "%{http_code}\\n" -X DELETE -u admin:${admin_password} -i http://localhost:3000/api/teams/"${id}" -H "Content-Type: application/json" -s
		fi
	else
		## Mark as a good team to sync
		if [ $1 == "--debug" ]; then
			echo "Adding Group ${g} to Good Group List"
		fi
		good_groups=( "${good_groups[@]}" "${g}" )
	fi
done

for g in ${good_groups[@]}
do
	if [ $1 == "--debug" ]; then
		echo "Checking if group ${g} exists in Grafana"
	fi
	output=$(curl -w "%{http_code}\\n" -u admin:${admin_password} -i http://localhost:3000/api/teams/search?name="${g}" -H "Content-Type: application/json" -s | grep "totalCount" | grep "totalCount" | cut -d':' -f 2 | cut -d',' -f 1)
	if [ ${output} -eq 0 ]; then
		## Create Group
		if [ $1 == "--debug" ]; then
			echo "Group ${g} doesn't exist, adding it"
		fi
		cat ${base_dir}/add_team_template.json | sed "s/FillTeamNameHere/${g}/" > add_team.json
		curl -w "%{http_code}\\n" -XPOST -u admin:${admin_password} -i http://localhost:3000/api/teams --data-binary @${base_dir}/add_team.json -H "Content-Type: application/json" -s
		rm -rf "${base_dir}/add_team.json"

		## Add to Array
		output=$(curl -w "%{http_code}\\n" -u admin:${admin_password} -i http://localhost:3000/api/teams/search?name="${g}" -H "Content-Type: application/json" -s)
		team_info=$(echo ${output} | grep "totalCount" | cut -d'"' -f 7,12 | sed 's/,"/,/' | cut -c 2-)
                teams=( "${teams[@]}" "${team_info}" )
                team_info=""
	else
		if [ $1 == "--debug" ]; then
			echo "Group ${g} exists"
		fi
		## Add to Array
		output=$(curl -w "%{http_code}\\n" -u admin:${admin_password} -i http://localhost:3000/api/teams/search?name="${g}" -H "Content-Type: application/json" -s)
		team_info=$(echo ${output} | grep "totalCount" | cut -d'"' -f 7,12 | sed 's/,"/,/' | cut -c 2-)
		teams=( "${teams[@]}" "${team_info}" )
		team_info=""
	fi
done

## Loop over unique usere; make sure in Grafana
for g in ${good_groups[@]}
do
	if [ $1 == "--debug" ]; then
		echo "Getting users in group ${g}"
	fi
	/usr/bin/ldapsearch -x "(cn=${g})" | grep uniqueMember | cut -d'=' -f 2 | cut -d',' -f 1 >> ${tfile}
done

unique_ldap_users=($(cat ${tfile} | sort -u))
rm -rf ${tfile}

for u in ${unique_ldap_users[@]}
do
	if [ $1 == "--debug" ]; then
		echo "Checking to make sure user ${u} is in Grafana"
	fi
	if [ -z "$(curl -w "%{http_code}\\n" -u admin:${admin_password} -i http://localhost:3000/api/users/lookup?loginOrEmail=${u} -H "Content-Type: application/json" -s | grep id\"\:)" ]; then
		## Add User
		if [ $1 == "--debug" ]; then
			echo "Adding User ${u} to Grafana"
		fi
		pretty_name=$(/usr/bin/ldapsearch -x "(uid=${u})" | grep "cn:" | cut -d' ' -f 2-)
		rp=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
		cat ${base_dir}/add_user_template.json | sed "s/NewUsersNameHere/${pretty_name}/" | sed "s/NewUserIDHere/${u}/" | sed "s/RandomPasswordHere/${rp}/" > add_user.json
		curl -w "%{http_code}\\n" -XPOST -u admin:${admin_password} -i http://localhost:3000/api/admin/users --data-binary @${base_dir}/add_user.json -H "Content-Type: application/json" -s
		rm -rf add_user.json
	fi
done


## Loop over Teams; Make sure they have all their users; Make sure users removed from teams no longer a part of
for t in ${teams[@]}
do
	## Get Team's Information
	id=$(echo ${t} | cut -d',' -f 1)
	name=$(echo ${t} | cut -d',' -f 2)
	if [ $1 == "--debug" ]; then
		echo "Making sure team ${name} has all users"
	fi
	curl -w "%{http_code}\\n" -u admin:${admin_password} -i http://localhost:3000/api/teams/${id}/members -H "Content-Type: application/json" -s > ${tfile}
	t_members=($(cat ${tfile} | grep orgId | sed -e 's/[{}]/''/g' |  awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep login | cut -d'"' -f 4))
	rm -rf ${tfile}
	## Get that team's real LDAP list
	l_members=($(/usr/bin/ldapsearch -x "(cn=${name})" | grep uniqueMember | cut -d'=' -f 2 | cut -d',' -f 1))

	## Check if any users need added to team and add them if so
	for l in ${l_members[@]}
	do
		if [ $1 == "--debug" ]; then
			echo "Making sure user: ${l} is in team:${name}"
		fi
		if [[ ! " ${t_members[@]} " =~ " ${l} " ]]; then
			## Get User's ID
			uid=$(curl -w "%{http_code}\\n" -u admin:${admin_password} -i http://localhost:3000/api/users/lookup?loginOrEmail=${l} -H "Content-Type: application/json" -s | grep \"id\"\: | cut -d',' -f 1 | cut -d':' -f 2)
			## Add User to team
			cat ${base_dir}/new_team_member_template.json | sed "s/NewUserIDGoesHere/${uid}/" > ${base_dir}/new_team_member.json
			curl -w "%{http_code}\\n" -XPOST -u admin:${admin_password} -i http://localhost:3000/api/teams/"${id}"/members --data-binary @${base_dir}/new_team_member.json -H "Content-Type: application/json" -s
			rm -rf ${base_dir}/new_team_member.json
		fi
	done
	
	## Check if any users need removed from team and remove them if so
	if [ $1 == "--debug" ]; then
		echo "Checking if there are users to remove from team: ${name}"
	fi
	for t in ${t_members[@]}
        do
		if [ $1 == "--debug" ]; then
			echo "Checking is user: ${t} belongs in team: ${name}"
		fi
                if [[ ! " ${l_members[@]} " =~ " ${t} " ]]; then
			## Get User's ID
			if [ $1 == "--debug" ]; then
				echo "Removing user: ${t} from team: ${name}"
			fi
			uid=$(curl -w "%{http_code}\\n" -u admin:${admin_password} -i http://localhost:3000/api/users/lookup?loginOrEmail=${t} -H "Content-Type: application/json" -s | grep \"id\"\: | cut -d',' -f 1 | cut -d':' -f 2)
                        ## Remove User from team
			curl -w "%{http_code}\\n" -X DELETE -u admin:${admin_password} -i http://localhost:3000/api/teams/"${id}"/members/"${uid}" -H "Content-Type: application/json" -s
                fi
        done
done

## Loop over grafana users; check if they're still in a valid team
grafana_users=($(curl -w "%{http_code}\\n" -u admin:${admin_password} -i http://localhost:3000/api/users -H "Content-Type: application/json" -s | grep \"id\"\: | sed -e 's/[{}]/''/g' |  awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep login | cut -d'"' -f 4 | grep -v admin))

for u in ${grafana_users[@]}
do
	if [ $1 == "--debug" ]; then
		echo "Checking to make sure ${u} is still in LDAP"
	fi
	if [[ ! " ${unique_ldap_users[@]} " =~ " ${u} " ]]; then
		## User ID
		if [ $1 == "--debug" ]; then
			echo "Removing user: ${u} as it is no longer in LDAP"
		fi
		uid=$(curl -w "%{http_code}\\n" -u admin:${admin_password} -i http://localhost:3000/api/users/lookup?loginOrEmail=${u} -H "Content-Type: application/json" -s | grep \"id\"\: | cut -d',' -f 1 | cut -d':' -f 2)

		## Delete User
		curl -w "%{http_code}\\n" -X DELETE -u admin:${admin_password} -i http://localhost:3000/api/admin/users/"${uid}" -H "Content-Type: application/json" -s
	fi
done

## Loop over grafana teams; remove if not in above definition
current_grafana_teams=($(curl -w "%{http_code}\\n" -u admin:${admin_password} -i http://localhost:3000/api/teams/search?perpage=1000 -H "Content-Type: application/json" -s | grep "totalCount" | sed -e 's/[{}]/''/g' |  awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep \"name\"\: | cut -d'"' -f 4))

for t in ${current_grafana_teams[@]}
do
	if [ $1 == "--debug" ]; then
		echo "Checking if team: ${t} Needs Removed from Grafana"
	fi
	if [[ ! " ${good_groups[@]} " =~ " ${t} " ]]; then
		## Remove Team from Grafana
		if [ $1 == "--debug" ]; then
			echo "Removing Team: ${t} due to removal from sync list"
		fi
		id=$(curl -w "%{http_code}\\n" -u admin:${admin_password} -i http://localhost:3000/api/teams/search?name="${t}" -H "Content-Type: application/json" -s | grep "totalCount" | cut -d':' -f 4 | cut -d',' -f 1)
                if [ -n "${id}" ]; then
                        curl -w "%{http_code}\\n" -X DELETE -u admin:${admin_password} -i http://localhost:3000/api/teams/"${id}" -H "Content-Type: application/json" -s
                fi
	fi
done
