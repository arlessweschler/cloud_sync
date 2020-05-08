#!/bin/bash

# set bigger font
setfont Uni2-TerminusBold32x16

export DIALOGRC=/home/pi/scripts/.dialogrc_red

dialog \
	--stdout \
	--colors \
	--backtitle "Back Title" \
	--title "Title" \
	--msgbox "RED" \
	10 20
	
export DIALOGRC=/home/pi/scripts/.dialogrc_green

dialog \
	--stdout \
	--colors \
	--backtitle "Back Title" \
	--title "Title" \
	--msgbox "GREEN" \
	10 20

# set default font
setfont Uni2-TerminusBold16

# clear the screen
clear