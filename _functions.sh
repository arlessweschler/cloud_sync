# Prints messages of different severities to a logfile
# Each message will look something like this:
# <TIMESTAMP>	<SEVERITY>	<CALLING_FUNCTION>	<MESSAGE>
# needs a set variable $logLevel
#	-1 > No logging at all
#	0 > prints ERRORS only
#	1 > prints ERRORS and WARNINGS
#	2 > prints ERRORS, WARNINGS and INFO
#	3 > prints ERRORS, WARNINGS, INFO and DEBUGGING
# needs a set variable $log pointing to a file
# Usage
# log 0 "This is an ERROR Message"
# log 1 "This is a WARNING"
# log 2 "This is just an INFO"
# log 3 "This is a DEBUG message"
function log () {
	severity=$1
	message=$2
	
	if [[ ${severity} -ge ${logLevel} ]]
	then
		case ${severity} in
			0) level="ERROR"  ;;
			1) level="WARNING"  ;;
			2) level="INFO"  ;;
			3) level="DEBUG"  ;;
		esac
		
		printf "$(date +%FT%T%:z):\t${level}\t${0##*/}\t${FUNCNAME[1]}\t${message}\n" >> ${logFile}
	fi
}

# prepare console with custom settings
function setConsole() {
	if [ "${USECUSTOMFONT}" == "ON" ]
	then
		# set bigger font
		setfont ${CUSTOMFONT}
	else
		# reset the default font
		setfont ${DEFAULTFONT}
	fi
}

# reset console to default settings
function resetConsole() {
	if [ "${USECUSTOMFONT}" == "ON" ]
	then
		# reset the default font
		setfont ${DEFAULTFONT}
	fi
	
	export DIALOGRC=

	# clear the screen
	clear
}

# set the DIALOGRC file
# INPUTS
#	1	> color
function setDRC() {
	export DIALOGRC=${WORKDIR}/.dialogrc_$1
}

# creates the custom local base directory for all saves if it doesn't exist and adds it as a SMB share
# RETURNS
#	0 > directory created successfully
#	1 > directory already exists
function createCustomLocalBaseDir() {
	if [ -d "${CUSTOMLOCALBASEDIR}" ]
	then
		log 2 "custom local basedir exists"
		return 1
	else
		mkdir "${CUSTOMLOCALBASEDIR}"
		
		# share that new directory on the network
		if [[ $(grep -c "\[saves\]" /etc/samba/smb.conf) -eq 0 ]]
		then
			# add new share to SAMBA
			printf "[saves]\ncomment = saves\npath = \"/home/pi/RetroPie/saves\"\nwritable = yes\nguest ok = yes\ncreate mask = 0644\ndirectory mask = 0755\nforce user = pi\n" | sudo tee --append /etc/samba/smb.conf | cat > /dev/null
			
			# restart SAMBA
			sudo service smbd restart
		fi
		
		log 2 "custom local basedir created"
		return 0
	fi
}

# creates the custom local system directory for all saves if it doesn't exist
# RETURNS
#	0 > directory created successfully
#	1 > directory already exists
function createCustomLocalSystemDir() {
	if [ -d "${CUSTOMLOCALBASEDIR}/${SYSTEM}" ]
	then
		log 2 "custom local systemdir exists"
		return 1
	else
		mkdir "${CUSTOMLOCALBASEDIR}/${SYSTEM}"
		log 2 "custom local systemdir created"
		return 0
	fi
}

# updates a given configuration file setting with a value
# INPUTS
#	1	> system
#	2	> setting
#	3	> value
function updateRetroArchConfig() {
	SYSTEM="$1"
	SETTING="$2"
	NEWVALUE="$3"
	
	BASECONFIGDIR="/opt/retropie/configs"
	CONFIGFILE="${BASECONFIGDIR}/${SYSTEM}/retroarch.cfg"
	log 2 "CONFIGFILE: ${CONFIGFILE}"
	log 2 "SETTING: ${SETTING}"
	log 2 "NEWVALUE: ${NEWVALUE}"
	
	OLDVALUE=$(getRetroArchConfig "${CONFIGFILE}" "${SETTING}")
	log 2 "OLDVALUE: ${OLDVALUE}"
	
	if [ "$OLDVALUE" == "$NEWVALUE" ]
	then
		log 2 "nothing do do"
		return
	fi
	
	if [ "${OLDVALUE}" == "n/a" ]
	then
		log 2 "add new setting to config file"
		LASTLINE="#include \"/opt/retropie/configs/all/retroarch.cfg\""
		
		# add new configuration settings above #include
		sed -i "s|${LASTLINE}|${SETTING} = \"${NEWVALUE}\"\n${LASTLINE}|g" ${CONFIGFILE}
		return
	fi
	
	if [ "$OLDVALUE" != "$NEWVALUE" ]
	then
		log 2 "replace value of setting"
		# update existing configuration setting with new value
		sed -i "s|^${SETTING} = \"${OLDVALUE}\"|${SETTING} = \"${NEWVALUE}\"|g" ${CONFIGFILE}
		return
	fi
}

# gets the value of a given setting in a configuration file
# INPUTS
#	1	> file
#	2	> setting
# RETURNS
#	value of setting
function getRetroArchConfig() {
	FILE="$1"
	SETTING="$2"
	
	COUNT=$(grep -i -c "^${SETTING} = " ${FILE})
	if [ "${COUNT}" == "0" ]
	then
		echo "n/a"
	fi

	VALUE=$(grep -i "^${SETTING} = " ${FILE})
	RETVAL=${VALUE//$SETTING = /}
	RETVAL=${RETVAL//\"/}
	echo "${RETVAL}"
}