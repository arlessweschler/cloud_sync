#!/bin/bash

####################
# INPUT PARAMETERS #
####################

DIRECTION="$1"
SYSTEM="$2"
EMULATOR="$3"
ROM="$4"
COMMAND="$5"

#########
# DEBUG #
#########

SYSTEM="snes"
EMULATOR="lr-snes9x"
ROM="/home/pi/RetroPie/roms/snes/Legend of Zelda, The - A Link to the Past (Germany).zip"
COMMAND="/opt/retropie/emulators/retroarch/bin/retroarch -L /opt/retropie/libretrocores/lr-snes9x/snes9x_libretro.so --config /opt/retropie/configs/snes/retroarch.cfg \"/home/pi/RetroPie/roms/snes/Legend of Zelda, The - A Link to the Past (Germany).zip\""


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
TITLE="Cloud Sync"
BACKTITLE="Cloud Sync (https://github.com/Jandalf81/cloud_sync)"
LOGFILE=/dev/shm/cloud_sync.log
MESSAGES=""

# load user config file
source ${WORKDIR}/cloud_sync.ini


#load functions
source ${WORKDIR}/_functions.sh

####################
# DIALOG FUNCTIONS #
####################


# update INFOBOX with message (stays on screen until overwritten or cleared)
# INPUTS
#	$1	> message text to append and show
function updateInfobox() {
	MESSAGES="${MESSAGES}$1"
	
	dialog \
		--stdout \
		--colors \
		--keep-tite \
		--backtitle "${BACKTITLE}" \
		--title "${TITLE}" \
		--ok-label "Back" \
		--infobox "${MESSAGES}" 25 75
}

# update PAUSEBOX with message (stays on screen for $1 seconds)
# INPUTS
#	$1	> message text to append and show
#	$2 	> timeout in seconds
function updatePause() {
	MESSAGES="${MESSAGES}$1"
	
	dialog \
		--stdout \
		--colors \
		--keep-tite \
		--backtitle "${BACKTITLE}" \
		--title "${TITLE}" \
		--ok-label "OK" \
		--pause "${MESSAGES}" 25 75 $2
}


######################
# INTERNAL FUNCTIONS #
######################

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
		#MESSAGES="${MESSAGES}${GREEN}OK${NORMAL}"
		return 0		
	fi
	
	GATEWAYIP=$(ip r | grep default | cut -d " " -f 3)
	if [ "${GATEWAYIP}" == "" ]
	then 
		#MESSAGES="${MESSAGES}${RED}ERROR${NORMAL}"
		return 2
	fi
	
	ping -q -w 1 -c 1 ${GATEWAYIP} > /dev/null
	if [[ $? -eq 0 ]]
	then
		#MESSAGES="${MESSAGES}${RED}ERROR${NORMAL}"
		return 1
	fi
}

# get the type of remote from configuration
function getTypeOfRemote () {
	# list all remotes and their type
	remotes=$(rclone listremotes --long)
	
	# get line with RETROPIE remote
	retval=$(grep -i "^retropie:" <<< ${remotes})

	REMOTETYPE="${retval#*:}"
	REMOTETYPE=$(echo ${REMOTETYPE} | xargs)
}

# split the path of ROM and set distinct variables
function splitPath() {
	ROMPATH="${ROM%/*}"
	ROMFILE="${ROM##*/}"
	ROMBASE="${ROMFILE%%.*}"
	ROMEXT="${ROMFILE#*.}"
}

# prepares the filter expression for RCLONE
function prepareFilter() {
	FILTER="${ROMBASE//\[/\\[}"
	FILTER="${FILTER//\]/\\]}"
}

function downloadSaves() {
	TITLE="Downloading"
	MESSAGES="Downloading saves and states for:\n${ROMBASE}\n\n"

	updateInfobox "Checking Internet access... "
	
	# check for Internet access, abort if disconnected
	checkInternet
	if [[ $? -ne 0 ]]
	then
		setDRC "red"
		updatePause "${RED}ERROR${NORMAL}\n\nYou seem to be disconnected. Could not sync!" ${TIMEOUT_ERROR}
		exitMenu
	fi
	updateInfobox "${GREEN}OK${NORMAL}"
	
	# check remote for existing files, WARNING if none found
	updateInfobox "\nListing remote files (${REMOTETYPE})... "
	LISTFILES=$(rclone lsf retropie:${REMOTEBASEDIR}/${SYSTEM} --include "${FILTER}.*")
	COUNTSRM=$(echo -n "${LISTFILES}" | grep -c "^.*\.srm")
	COUNTSTATE=$(echo -n "${LISTFILES}" | grep -c "^.*\.state.*")
	
	if [ "${COUNTSRM}" -gt 0 -o "${COUNTSTATE}" -gt 0 ]
	then
		updateInfobox "${GREEN}OK${NORMAL}\nFound ${COUNTSRM} battery save(s) and ${COUNTSTATE} save state(s)"
		
		# download files, show result, start game
		updateInfobox "\nDownloading save(s) and state(s)... "
		rclone copy retropie:${REMOTEBASEDIR}/${SYSTEM} ${LOCALBASEDIR}/${SYSTEM} --include "${FILTER}.*" --update
		retval=$?
		if [ "${retval}" == "0" ]
		then
			setDRC "green"
			updatePause "${GREEN}OK${NORMAL}\n\nStarting game..." ${TIMEOUT_OK}
			exitMenu
		else
			setDRC "red"
			updatePause "${RED}ERROR${NORMAL}\n\nStarting game..." ${TIMEOUT_ERROR}
			exitMenu
		fi
	else
		setDRC "yellow"
		updatePause "${YELLOW}WARNING${NORMAL}\nNo remote files found" ${TIMEOUT_ERROR}
		exitMenu
	fi
	
	
	updatePause "" ${TIMEOUT_ERROR}
	mainMenu
}


function exitMenu () {
	resetConsole
	exit
}



#############
# MAIN LOOP #
#############

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
				1 "downloadSaves OK" \
				2 "downloadSaves ERROR"
		)
		
		case "${CHOICE}" in
			1) 
				getTypeOfRemote
				splitPath
				prepareFilter
				downloadSaves  
				;;
			2) 
				ROM="/home/pi/RetroPie/roms/snes/Ich bin grandioser Blödsinn.zip"
				getTypeOfRemote
				splitPath
				prepareFilter
				downloadSaves  
				;;
			*) 
				exitMenu  
				;;
		esac
	done
}

setConsole
mainMenu