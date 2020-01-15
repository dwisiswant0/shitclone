#!/bin/bash

LIST_REPOS="/tmp/repos.json"
DEST_APPS="$HOME/apps"

# TO DO: this should be passed by an argument and not written stupidly here,
# 		 I'm just in a hurry 'coz my harddisk is fucking broken
GITHUB_USER="..."
GITHUB_TOKEN="..."
GITHUB_ORG="..."
GITHUB_TEAM_ID="..."

init() {
	echo "[#] Getting all repos..."
	REPOS_ENDPOINT="https://$GITHUB_AT:@api.github.com/orgs/${GITHUB_ORG}/repos?per_page=200" # for team "/teams/:team_id/repos", for user (/users/:username/repos) # TO DO
	REPOS_GET="curl -s "${REPOS_ENDPOINT}""
	[[ ! -z $GITHUB_USER || ! -z $GITHUB_TOKEN ]] && REPOS_GET+=" -u ${GITHUB_USER}:${GITHUB_TOKEN}"
	REPOS_LIST=$(echo $(eval "$REPOS_GET") | jq '.[] | select((.fork)==false)' | jq '.ssh_url' | sed "s/\"//g" > ${LIST_REPOS})
	doClone
}

doClone() {
	cat $LIST_REPOS | while read -r REPO_URL
	do
		cd "${DEST_APPS}"
		REPO_NAME=$(echo "${REPO_URL}" | sed "s/.git//g; s/github.com:${GITHUB_ORG}\///g;")
		if [ -d "${PWD}/${REPO_NAME}" ]; then 
			# REPO_URL=$(echo ${CLONE} | awk '{print $1}' | sed "s/'//g")
			echo "[!] ${REPO_NAME} exist"
			cd "${REPO_NAME}"
			echo "[#] Pulling ${REPO_NAME}..."
			doPull
		else
			echo "[#] Cloning ${REPO_URL}..."
			CLONE=$(git clone ${REPO_URL})
		fi
		[ ! -z "$EXEC" ] && doSomeShit $EXEC
	done
}

doPull() {
        PULL=$(git checkout HEAD && git pull)
        if echo "${PULL}" | grep -q "up to date"; then
                echo "[!] Branch up to date! Skip..."
        else
                echo ${PULL}
        fi
}

doSomeShit() {
	(exec $1)
}

showUsage() {
	echo "Usage: ${0##*/} -e=[shell...]"
	echo -e " -e, --exec\tDo some shit inside each of repository,"
	echo -e "\t\tshell or file exec"
	echo -e " -h\t\tThis help text"
}

for i in "$@"
do
	case $i in
		-e=* | --exec=* )
		EXEC="${i#*=}"
		shift
		;;
		-h | --help )
		showUsage
		exit 1
		;;
	esac
done

init