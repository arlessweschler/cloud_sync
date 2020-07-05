#!/bin/bash

# define colors for output
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

# global variables
URL="https://raw.githubusercontent.com/Jandalf81/cloud_sync"
BRANCH="master"

TARGETDIR="/home/pi/scripts/cloud_sync"

BACKTITLE="Cloud Sync Installer (https://github.com/Jandalf81/cloud_sync)"
TITLE="Installer"

MESSAGES=""

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

#######################
# INSTALLER FUNCTIONS #
#######################

function installRCLONE() {
	updateInfobox "Installing RCLONE...\n"
	
	if [ ! -f /usr/bin/rclone ]
	then
		updateInfobox "   RCLONE not found, installing...\n"
		getLatestRCLONE		
	else
		updateInfobox "   RCLONE is installed, checking version...\n"
		
		CURRENTVERSION=$(curl -s https://downloads.rclone.org/version.txt)
		INSTALLEDVERSION=$(rclone version | head -n 1)
		
		if [ "${CURRENTVERSION}" = "${INSTALLEDVERSION}" ]
		then
			updateInfobox "   Latest version (${CURRENTVERSION}) already installed\n"
		else
			updateInfobox "   Newer version (${CURRENTVERSION}) found, updating...\n"
			
			updateInfobox "   Removing old version...\n"
			sudo rm /usr/bin/rclone
			
			getLatestRCLONE
		fi
	fi
}

function getLatestRCLONE() {
	updateInfobox "   Getting files...\n"
	wget -P ~ https://downloads.rclone.org/rclone-current-linux-arm.zip
	unzip ~/rclone-current-linux-arm.zip -d ~
	cd ~/rclone-v*
	
	updateInfobox "   Moving files...\n"
	sudo mv rclone /usr/bin
	
	updateInfobox "   Making files executable...\n"
	sudo chown root:root /usr/bin/rclone
	sudo chmod 755 /usr/bin/rclone
	
	updateInfobox "   Removing temp files...\n"
	cd ~
	rm ~/rclone-current-linux-arm.zip
	rm -r ~/rclone-v*
	
	updateInfobox "   ${GREEN}OK${NORMAL}\n"
}


function installCLOUD_SYNC() {
	updateInfobox "Installing CLOUD_SYNC...\n"
	
	if [ ! -d "${TARGETDIR}" ]
	then
		updateInfobox "   Creating new directory...\n"
		mkdir "${TARGETDIR}"
	fi
	
	updateInfobox "   Getting files...\n"
	wget -q -N -P "${TARGETDIR}" "${URL}/${BRANCH}/.dialogrc_blue"
	wget -q -N -P "${TARGETDIR}" "${URL}/${BRANCH}/.dialogrc_green"
	wget -q -N -P "${TARGETDIR}" "${URL}/${BRANCH}/.dialogrc_red"
	wget -q -N -P "${TARGETDIR}" "${URL}/${BRANCH}/.dialogrc_yellow"
	wget -q -N -P "${TARGETDIR}" "${URL}/${BRANCH}/_functions.sh"
	wget -q -N -P "${TARGETDIR}" "${URL}/${BRANCH}/cloud_sync-menu.sh"
	wget -q -N -P "${TARGETDIR}" "${URL}/${BRANCH}/cloud_sync.ini"
	wget -q -N -P "${TARGETDIR}" "${URL}/${BRANCH}/cloud_sync.sh"
	
	updateInfobox "   Making files executable...\n"
	chmod +x "${TARGETDIR}/cloud_sync-menu.sh"
	chmod +x "${TARGETDIR}/cloud_sync.sh"
	
	updateInfobox "   Creating RetroPie menu entry...\n"
	printf "#!/bin/bash\n${TARGETDIR}/cloud_sync-menu.sh" > ~/RetroPie/retropiemenu/cloud_sync-redirect.sh
	chmod +x ~/RetroPie/retropiemenu/cloud_sync-redirect.sh
	
	if [[ $(xmlstarlet sel -t -v "count(/gameList/game[path='./cloud_sync-redirect.sh'])" ~/.emulationstation/gamelists/retropie/gamelist.xml) -eq 0 ]]
	then
		xmlstarlet ed \
			--inplace \
			--subnode "/gameList" --type elem -n game -v ""  \
			--subnode "/gameList/game[last()]" --type elem -n path -v "./cloud_sync-redirect.sh" \
			--subnode "/gameList/game[last()]" --type elem -n name -v "CLOUD_SYNC menu" \
			--subnode "/gameList/game[last()]" --type elem -n desc -v "Configuration for CLOUD_SYNC" \
			--subnode "/gameList/game[last()]" --type elem -n image -v "./icons/cloudsync.png" \
			~/.emulationstation/gamelists/retropie/gamelist.xml
	fi
	
	updateInfobox "   ${GREEN}OK${NORMAL}\n"
}

function configureRUNCOMMAND() {
	updateInfobox "Configuring RUNCOMMAND...\n"
	
	if [ ! -f /opt/retropie/configs/all/runcommand-onstart.sh ]
	then
		updateInfobox "   No RUNNCOMMAND-ONSTART found, creating...\n"
		printf "#!/bin/bash\n${TARGETDIR}/cloud_sync.sh \"DOWN\" \"\$1\" \"\$2\" \"\$3\" \"\$4\"\n" > /opt/retropie/configs/all/runcommand-onstart.sh
	else
		updateInfobox "   RUNCOMMAND-ONSTART found, checking for call...\n"
		if grep -Fq "${TARGETDIR}/cloud_sync.sh" /opt/retropie/configs/all/runcommand-onstart.sh
		then
			updateInfobox "   Call found\n"
		else
			updateInfobox "   Call not found, creating...\n"
			printf "\n${TARGETDIR}/cloud_sync.sh \"DOWN\" \"\$1\" \"\$2\" \"\$3\" \"\$4\"\n" >> /opt/retropie/configs/all/runcommand-onstart.sh
		fi
	fi
	
	if [ ! -f /opt/retropie/configs/all/runcommand-onend.sh ]
	then
		updateInfobox "   No RUNCOMMAND-ONEND found, creating...\n"
		printf "#!/bin/bash\n${TARGETDIR}/cloud_sync.sh \"UP\" \"\$1\" \"\$2\" \"\$3\" \"\$4\"\n" > /opt/retropie/configs/all/runcommand-onend.sh
	else
		updateInfobox "   RUNCOMMAND-ONEND found, checking for call...\n"
		if grep -Fq "${TARGETDIR}/cloud_sync.sh" /opt/retropie/configs/all/runcommand-onend.sh
		then
			updateInfobox "   Call found\n"
		else
			updateInfobox "   Call not found, creating...\n"
			printf "\n${TARGETDIR}/cloud_sync.sh \"UP\" \"\$1\" \"\$2\" \"\$3\" \"\$4\"\n" >> /opt/retropie/configs/all/runcommand-onend.sh
		fi
	fi
}

function configureRCLONE() {
	updateInfobox "Configuring RCLONE...\n"
}

########
# main #
########

installRCLONE
installCLOUD_SYNC
configureRUNCOMMAND
configureRCLONE