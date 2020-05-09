#!/bin/bash

# script variables
WORKDIR=$(pwd)
BACKTITLE="Cloud Sync (https://github.com/Jandalf81/cloud_sync)"

LOGFILE=/dev/shm/cloud_sync.log


# load user config file
source ${WORKDIR}/cloud_sync.ini

function setConsole () {
	# set bigger font
	setfont Uni2-TerminusBold32x16
}


function mainMenu () {
	while true
	do
		CHOICE=$(dialog \
			--stdout \
			--colors \
			--backtitle "${BACKTITLE}" \
			--title "main Menu" \
			--ok-label "OK" \
			--cancel-label "Exit" \
			--menu "What to do?" 25 75 20 \
				1 "Check Internet access" \
				2 "Choose .dialogrc"
		)
		
		case "${CHOICE}" in
			1) doInternetCheck  ;;
			2) chooseDialogRC  ;;
			*) exitMenu  ;;
		esac
	done
}

function chooseDialogRC () {
	while true
	do	
		CHOICE=$(dialog \
			--stdout \
			--colors \
			--backtitle "${BACKTITLE}" \
			--title "Choose DialogRC" \
			--ok-label "Set" \
			--cancel-label "Back" \
			--menu "Select a file" 25 75 20 \
				1 ".dialogrc_blue" \
				2 ".dialogrc_green" \
				3 ".dialogrc_red"
		)
		
		case "${CHOICE}" in
			1) export DIALOGRC=${WORKDIR}/.dialogrc_blue  ;;
			2) export DIALOGRC=${WORKDIR}/.dialogrc_green  ;;
			3) export DIALOGRC=${WORKDIR}/.dialogrc_red  ;;
			*) break  ;;
		esac
	done
}


function doInternetCheck () {
	dialog \
		--stdout \
		--colors \
		--backtitle "${BACKTITLE}" \
		--title "Checking Internet access..." \
		--ok-label "Back" \
		--infobox "Checking Internet access..." 25 75
	
	checkInternet
	RESULT=$?
	
	case ${RESULT} in
		0) 	export DIALOGRC=${WORKDIR}/.dialogrc_green
			TEXT="Success!"
			TIMEOUT=$TIMEOUT_OK  ;;
		1)	export DIALOGRC=${WORKDIR}/.dialogrc_red
			TEXT="Error, no Internet access detected"
			TIMEOUT=${TIMEOUT_ERROR}  ;;
		2)	export DIALOGRC=${WORKDIR}/.dialogrc_red
			TEXT="Error, no LAN / WLAN access detected"
			TIMEOUT=${TIMEOUT_ERROR}  ;;
	esac
	
	echo ${TIMEOUT}
	
	dialog \
		--stdout \
		--colors \
		--backtitle "${BACKTITLE}" \
		--title "Checking Internet access..." \
		--ok-label "Back" \
		--pause "${TEXT}" 25 75 ${TIMEOUT}
	
	mainMenu
}


function exitMenu () {
	resetConsole
	exit
}

# check for Internet access
# RETURNS
#	0 	> OK
#	1	> LAN / WLAN connected but no Internet
#	2	> no LAN / WLAN connected
function checkInternet() {
	# ping Google DNS
	ping -q -w 1 -c 1 "8.8.8.8" > /dev/null
	
	if [[ $? -eq 0 ]]
	then
		return 0		
	fi
	
	GATEWAYIP=$(ip r | grep default | cut -d " " -f 3)
	if [ "${GATEWAYIP}" == "" ]
	then 
		return 2
	fi
	
	ping -q -w 1 -c 1 ${GATEWAYIP} > /dev/null
	if [[ $? -eq 0 ]]
	then
		return 1
	fi
}


function resetConsole () {
	# reset the default font
	setfont Uni2-TerminusBold16
	
	export DIALOGRC=

	# clear the screen
	clear
}


setConsole
mainMenu