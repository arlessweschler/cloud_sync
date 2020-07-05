#!/bin/bash

####################
# INPUT PARAMETERS #
####################

DIRECTION="$1"
SYSTEM="$2"
EMULATOR="$3"
ROM="$4"
COMMAND="$5"

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

function prepareLocalDirectories() {
	if [ "${USECUSTOMLOCALBASEDIR}" == "ON" ]
	then
		TITLE="Preparing"
		
		updateInfobox "Checking local base directory... "
		createCustomLocalBaseDir
		case "$?" in
			0) updateInfobox "${GREEN}OK, created${NORMAL}\n"  ;;
			1) updateInfobox "${GREEN}OK, exists${NORMAL}\n"  ;;
		esac
		
		updateInfobox "Checking local system directory... "
		createCustomLocalSystemDir
		case "$?" in
			0) updateInfobox "${GREEN}OK, created${NORMAL}\n"  ;;
			1) updateInfobox "${GREEN}OK, exists${NORMAL}\n"  ;;
		esac
		
		LOCALDIRECTORY="${CUSTOMLOCALBASEDIR}/${SYSTEM}"
		REMOTEDIRECTORY="${REMOTEBASEDIR}/${SYSTEM}"
	else
		LOCALDIRECTORY="${ROMPATH}"
		REMOTEDIRECTORY="${REMOTEBASEDIR}/${SYSTEM}"
	fi
}

function prepareRetroArchConfig() {
	if [ "${USECUSTOMLOCALBASEDIR}" == "ON" ]
	then
		updateRetroArchConfig "${SYSTEM}" "savefile_directory" "${LOCALDIRECTORY}"
		updateRetroArchConfig "${SYSTEM}" "savestate_directory" "${LOCALDIRECTORY}"
	else
		updateRetroArchConfig "${SYSTEM}" "savefile_directory" "${LOCALDIRECTORY}"
		updateRetroArchConfig "${SYSTEM}" "savestate_directory" "${LOCALDIRECTORY}"
	fi
}

function downloadSaves() {
	TITLE="Downloading"
	updateInfobox "\nDownloading saves and states for:\n${ROMBASE}\n\n"

	# check for Internet access, abort if disconnected
	updateInfobox "Checking Internet access... "
	
	checkInternet
	if [[ $? -ne 0 ]]
	then
		log 2 "No Internet access"
		setDRC "red"
		updatePause "${RED}ERROR${NORMAL}\n\nYou seem to be disconnected. Could not sync!" ${TIMEOUT_ERROR}
		exitMenu
	fi
	log 2 "Internet accessible"
	updateInfobox "${GREEN}OK${NORMAL}"
	
	# check remote for existing files, WARNING if none found
	updateInfobox "\nListing remote files (${REMOTETYPE})... "
	LISTFILES=$(rclone lsf retropie:${REMOTEBASEDIR}/${SYSTEM} --include "${FILTER}.*")
	COUNTSRM=$(echo -n "${LISTFILES}" | grep -c "^.*\.srm")
	COUNTSTATE=$(echo -n "${LISTFILES}" | grep -c "^.*\.state.*")
	
	if [ "${COUNTSRM}" -gt 0 -o "${COUNTSTATE}" -gt 0 ]
	then
		log 2 "Found remote files: ${COUNTSRM} battery save(s) and ${COUNTSTATE} save state(s)"
		updateInfobox "${GREEN}OK${NORMAL}\nFound ${COUNTSRM} battery save(s) and ${COUNTSTATE} save state(s)"
		
		# download files, show result, start game
		updateInfobox "\nDownloading save(s) and state(s) to ${LOCALDIRECTORY}... "
		rclone copy "retropie:${REMOTEDIRECTORY}" "${LOCALDIRECTORY}" --include "${FILTER}.*" --update
		retval=$?
		if [ "${retval}" == "0" ]
		then
			log 2 "Download successful"
			setDRC "green"
			updatePause "${GREEN}OK${NORMAL}\n\nStarting game..." ${TIMEOUT_OK}
			exitMenu
		else
			log 0 "ERROR while downloading!"
			setDRC "red"
			updatePause "${RED}ERROR${NORMAL}\n\nStarting game..." ${TIMEOUT_ERROR}
			exitMenu
		fi
	else
		log 2 "No remote files found"
		setDRC "yellow"
		updatePause "${YELLOW}WARNING${NORMAL}\nNo remote files found" ${TIMEOUT_ERROR}
		exitMenu
	fi
	
	updatePause "" ${TIMEOUT_ERROR}
}

function uploadSaves() {
	TITLE="Uploading"
	updateInfobox "\nUploading saves and states for:\n${ROMBASE}\n\n"

	# check for Internet access, abort if disconnected
	updateInfobox "Checking Internet access... "
	
	checkInternet
	if [[ $? -ne 0 ]]
	then
		log 2 "No Internet access"
		setDRC "red"
		updatePause "${RED}ERROR${NORMAL}\n\nYou seem to be disconnected. Could not sync!" ${TIMEOUT_ERROR}
		exitMenu
	fi
	log 2 "Internet accessible"
	updateInfobox "${GREEN}OK${NORMAL}\n"
	
	# check local dir for existing files
	updateInfobox "Listing local files... "
	LISTFILES=$(find "${LOCALDIRECTORY}" -type f -iname "${FILTER}.*")
	COUNTSRM=$(echo -n "${LISTFILES}" | grep -c "^.*\.srm")
	COUNTSTATE=$(echo -n "${LISTFILES}" | grep -c "^.*\.state.*")
	
	if [ "${COUNTSRM}" -gt 0 -o "${COUNTSTATE}" -gt 0 ]
	then
		log 2 "Found local files: ${COUNTSRM} battery save(s) and ${COUNTSTATE} save state(s)"
		updateInfobox "${GREEN}OK${NORMAL}\nFound ${COUNTSRM} battery save(s) and ${COUNTSTATE} save state(s)\n"
		
		# upload files, show result, start game
		updateInfobox "Uploading save(s) and state(s) to ${REMOTEDIRECTORY}... "
		rclone copy "${LOCALDIRECTORY}" "retropie:${REMOTEDIRECTORY}" --include "${FILTER}.*" --update
		
		retval=$?
		if [ "${retval}" == "0" ]
		then
			log 2 "Upload successful"
			setDRC "green"
			updatePause "${GREEN}OK${NORMAL}\n\nStarting game..." ${TIMEOUT_OK}
			exitMenu
		else
			log 0 "ERROR while downloading!"
			setDRC "red"
			updatePause "${RED}ERROR${NORMAL}\n\nExitting game..." ${TIMEOUT_ERROR}
			exitMenu
		fi
	else
		log 2 "No local files found"
		setDRC "yellow"
		updatePause "${YELLOW}WARNING${NORMAL}\nNo local files found" ${TIMEOUT_ERROR}
		exitMenu
	fi
	
	updatePause "" ${TIMEOUT_ERROR}
}

function exitMenu () {
	resetConsole
	exit
}



#############
# MAIN LOOP #
#############

function main() {
	log 2 "Started main()"
	log 2 "DIRECTION: ${DIRECTION}"
	log 2 "SYSTEM: ${SYSTEM}"
	log 2 "ROM: ${ROM}"
	MESSAGES=""

	getTypeOfRemote
	splitPath
	prepareFilter
	
	prepareLocalDirectories
	prepareRetroArchConfig
	
	if [ "${DIRECTION}" ==  "DOWN" ]
	then
		downloadSaves
	fi
	
	if [ "${DIRECTION}" ==  "UP" ]
	then
		uploadSaves
	fi
	
	log 2 "Ended main()"
}

setConsole
main