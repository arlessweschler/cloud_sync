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
WORKDIR="$(dirname "$0")"
TITLE="Cloud Sync Menu"
BACKTITLE="Cloud Sync (https://github.com/Jandalf81/cloud_sync) ${WORKDIR}"

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
			--ok-label "Set / Toggle" \
			--extra-button \
			--extra-label "Save" \
			--cancel-label "Cancel" \
			--default-item "${mmCHOICE}" \
			--menu "Configuration" 25 75 20 \
				1 "Sync on start/stop:	${tDOSYNC}" \
				2 "Use custom local dir:	${tUSECUSTOMLOCALBASEDIR}" \
				3 "Custom local dir:		${CUSTOMLOCALBASEDIR}" \
				4 "Timeout on OK:		${TIMEOUT_OK}" \
				5 "Timeout on ERROR:		${TIMEOUT_ERROR}" \
				6 "Use custom font:		${tUSECUSTOMFONT}" \
				7 "Custom font:	 	${CUSTOMFONT}"
		)
		
		ret=$?
		if [ "${ret}" == "3" ]
		then
			exitWithSave
		fi
		
		case "${mmCHOICE}" in
			1) toggleDOSYNC  ;;
			2) toggleUSECUSTOMLOCALBASEDIR  ;;
			3) setCUSTOMLOCALBASEDIR  ;;
			4) setTIMEOUT_OK  ;;
			5) setTIMEOUT_ERROR  ;;
			6) toggleUSECUSTOMFONT  ;;
			7) selectCUSTOMFONT  ;;
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
	
	if [ "${USECUSTOMLOCALBASEDIR}" == "ON" ]
	then
		tUSECUSTOMLOCALBASEDIR=${GREEN}ON${NORMAL}
	else
		tUSECUSTOMLOCALBASEDIR=${RED}OFF${NORMAL}
	fi
	
	if [ "${USECUSTOMFONT}" == "ON" ]
	then
		tUSECUSTOMFONT=${GREEN}ON${NORMAL}
	else
		tUSECUSTOMFONT=${RED}OFF${NORMAL}
	fi
}

function exitWithSave() {
	resetConsole
	saveSettings
	exit
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

function toggleUSECUSTOMLOCALBASEDIR() {
	if [ "${USECUSTOMLOCALBASEDIR}" == "ON" ]
	then
		USECUSTOMLOCALBASEDIR=OFF
	else
		USECUSTOMLOCALBASEDIR=ON
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

function saveSettings() {
	settings="DOSYNC=${DOSYNC}

USECUSTOMFONT=${USECUSTOMFONT}
CUSTOMFONT=${CUSTOMFONT}
DEFAULTFONT=${DEFAULTFONT}

USECUSTOMLOCALBASEDIR=${USECUSTOMLOCALBASEDIR}
CUSTOMLOCALBASEDIR=${CUSTOMLOCALBASEDIR}
REMOTEBASEDIR=${REMOTEBASEDIR}

TIMEOUT_OK=${TIMEOUT_OK}
TIMEOUT_ERROR=${TIMEOUT_ERROR}

logLevel=${logLevel}
logFile=${logFile}"

	echo "${settings}" > ${WORKDIR}/cloud_sync.ini
}

#############
# MAIN LOOP #
#############

setConsole
mainMenu