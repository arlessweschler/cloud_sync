#!/bin/bash

########################
# VARIABLE DEFINITIONS #
########################

# color variables
NORMAL="\Zn"
BLACK="\Z0"
RED="\Z1"
GREEN="\Z2"
YELLOW="\Z3\Zb"
BLUE="\Z4"
MAGENTA="\Z5"
CYAN="\Z6"
WHITE="\Z7"
BOLD="\Zb"
REVERSE="\Zr"
UNDERLINE="\Zu"

# script variables
WORKDIR="$(pwd)"
TITLE="Cloud Sync Menu"
BACKTITLE="Cloud Sync (https://github.com/Jandalf81/cloud_sync)"

# load user config file
source ${WORKDIR}/cloud_sync.ini

#load functions
source ${WORKDIR}/_functions.sh

####################
# DIALOG FUNCTIONS #
####################

# main menu
function mainMenu() {
	while true
	do
		prepareToggles
		
		mmCHOICE=$(dialog \
			--stdout \
			--colors \
			--keep-tite \
			--backtitle "${BACKTITLE}" \
			--title "${TITLE}" \
			--cancel-label "Exit" \
			--default-item "${mmCHOICE}" \
			--menu "Configuration" 25 75 20 \
				1 "Sync on start/stop:	${tDOSYNC}" \
				2 "Timeout on OK:		${TIMEOUT_OK}" \
				3 "Timeout on ERROR:		${TIMEOUT_ERROR}" \
				4 "Use custom font:		${tUSECUSTOMFONT}" \
				5 "Custom font:	 	${CUSTOMFONT}"
		)
		
		case "${mmCHOICE}" in
			1) toggleDOSYNC  ;;
			2) setTIMEOUT_OK  ;;
			3) setTIMEOUT_ERROR  ;;
			4) toggleUSECUSTOMFONT  ;;
			5) selectCUSTOMFONT  ;;
			*) exitMenu  ;;
		esac
	done
}

function prepareToggles() {
	if [ "${DOSYNC}" == "ON" ]
	then
		tDOSYNC=${GREEN}ON${NORMAL}
	else
		tDOSYNC=${RED}OFF${NORMAL}
	fi
	
	if [ "${USECUSTOMFONT}" == "ON" ]
	then
		tUSECUSTOMFONT=${GREEN}ON${NORMAL}
	else
		tUSECUSTOMFONT=${RED}OFF${NORMAL}
	fi
}

function exitMenu() {
	resetConsole
	exit
}


###########################
# CONFIGURATION FUNCTIONS #
###########################

function toggleDOSYNC() {
	if [ "${DOSYNC}" == "ON" ]
	then
		DOSYNC=OFF
	else
		DOSYNC=ON
	fi
	
	mainMenu
}

function setTIMEOUT_OK() {
	RETVAL=$(dialog \
		--stdout \
		--colors \
		--backtitle "${BACKTITLE}" \
		--title "${TITLE}" \
		--ok-label "Set" \
		--cancel-label "Cancel" \
		--rangebox "Set Timeout on OK (currently ${TIMEOUT_OK})" 2 75 0 20 ${TIMEOUT_OK}
	)
	
	if [ "${RETVAL}" ]
	then
		TIMEOUT_OK=${RETVAL}
	fi
}

function setTIMEOUT_ERROR() {
	RETVAL=$(dialog \
		--stdout \
		--colors \
		--backtitle "${BACKTITLE}" \
		--title "${TITLE}" \
		--ok-label "Set" \
		--cancel-label "Cancel" \
		--rangebox "Set Timeout on ERROR (currently ${TIMEOUT_ERROR})" 2 75 0 20 ${TIMEOUT_ERROR}
	)
	
	if [ "${RETVAL}" ]
	then
		TIMEOUT_ERROR=${RETVAL}
	fi
}

function toggleUSECUSTOMFONT() {
	if [ "${USECUSTOMFONT}" == "ON" ]
	then
		USECUSTOMFONT=OFF
	else
		USECUSTOMFONT=ON
	fi
	
	setConsole
	mainMenu
}

function selectCUSTOMFONT() {
	RETVAL=$(dialog \
		--stdout \
		--colors \
		--backtitle "${BACKTITLE}" \
		--title "${TITLE}" \
		--fselect "/usr/share/consolefonts/" 25 75
	)
	
	echo "RETVAL: ${RETVAL}"
	
	FILE=${RETVAL##*/}
	
	echo "FILE: ${FILE}"
	
	if [ ! -z "${FILE}" ]
	then
		CUSTOMFONT=${FILE}
		setConsole
	fi
}


#############
# MAIN LOOP #
#############

setConsole
mainMenu