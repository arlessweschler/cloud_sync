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