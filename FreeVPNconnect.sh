#!/bin/bash
#Author: Sebastijan Bandur
#Email: seba.bandur@gmail.com
#Licecnce: GPL v2
SELECTED_PROFILE=""
PASSWORD=""
USERNAME=""
USER_BOOK="vpnbook"
USER_ME="freevpnme"
USER_KEYS="vpnkeys"
URL_VPNBOOK="http://www.vpnbook.com/freevpn"
URL_VPNBOOK_PROFILES="http://www.vpnbook.com/free-openvpn-account/VPNBook.com-OpenVPN-Euro1.zip http://www.vpnbook.com/free-openvpn-account/VPNBook.com-OpenVPN-Euro2.zip http://www.vpnbook.com/free-openvpn-account/VPNBook.com-OpenVPN-US2.zip http://www.vpnbook.com/free-openvpn-account/VPNBook.com-OpenVPN-CA1.zip http://www.vpnbook.com/free-openvpn-account/VPNBook.com-OpenVPN-DE1.zip"
URL_FREEVPNME="http://freevpn.me/accounts/"
URL_FREEVPNME_PROFILES="http://freevpn.me/OpenVPN-Certificate-Bundle-Server1.zip"
URL_VPNKEYS="https://www.vpnkeys.com/get-free-vpn-instantly/"
URL_VPNKEYS_PROFILES="https://www.vpnkeys.com/us1.zip https://www.vpnkeys.com/uk1.zip https://www.vpnkeys.com/nl1.zip https://www.vpnkeys.com/sg1.zip"
IMPORTANT="IMPORTANT! Press CTRL+C to end when in connection!"
INFO=$IMPORTANT
PROFILES_DIR="PROFILES"
PASSWORD_FILE="vpnuserpass"

#clear screen
function CLS
{
	printf "\033c" # clear screen
}

function PrintTopMenuInfo()
{
	echo "––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––"
	echo "––––––––––––––––––– Free VPN Connect for linux - MAIN MENU –––––––––––––––––––––"
	echo "––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––"
	echo "––––– Supported services: www.FreeVPN.me, www.VPNbook.com, www.VPNkeys.com –––––"
	echo "––––––––––– Please donate to continue supporting free VPN services –––––––––––––"
	echo "––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––"
}



#usage: ChangeColor $COLOR text/background
function ChangeColor()
{
	TYPE=""
	case "$2" in
	"text") TYPE="setaf"
	;;
	"back") TYPE="setab"
	;;
	*) TYPE="setaf"
	esac



	case "$1" in
	"red") tput "$TYPE" 1
	;;
	"orange") tput "$TYPE" 3
	;;
	"blue") tput "$TYPE" 4
	;;
	"green") tput "$TYPE" 2
	;;
	"black") tput "$TYPE" 0
	;;
	"white") tput "$TYPE" 7
	;;
	"magenta") tput "$TYPE" 5
	;;
	"cyan") tput "$TYPE" 7
	;;
	*) tput "$TYPE" 0
	esac
}

#usage: DownloadProfile $URL
function DownloadProfile()
{
	#current dir
	DIR=$(pwd)
	#if profiles dir does not exist create it and enter
	if [ ! -d "$DIR/$PROFILES_DIR" ]
	then mkdir "$DIR/$PROFILES_DIR"
	fi
	cd "$DIR/$PROFILES_DIR"
	wget $1
	FILE=$(ls *.zip)
	unzip -j "$FILE"
	rm $FILE
	INFO="Profiles added: $FILE"
	cd $DIR
		
}

function ClearProfiles()
{
	#current dir
	DIR=$(pwd)
	cd $PROFILES_DIR
	rm *.ovpn
	cd $DIR
	INFO="All profiles removed!"
	SELECTED_PROFILE=""
	PASSWORD=""
	USERNAME=""
}

#USAGE: UpdatePassword $URL_ $USER_
function UpdatePassword()
{
	URL=$1
	USERNAME=$2
	local DIR=$(pwd)
	## SCRIPT FOR GETTING PASSWORD FROM VPNBOOK - FREE VPN
	local SAVE_TO="$DIR/$PROFILES_DIR/$PASSWORD_FILE"
	
	PASSWORD_LINE_PHARSE="Password"
	
	## get page with password | find line with pass | get last line | remove white spaces   
	local PWD=$(wget -T 2 -q -O - "$@" "$url" | grep -n "$PASSWORD_LINE_PHARSE" | tail -1 | tr -d ' ')

	### for PWD we get: 154: <li>Password:<strong>fra4agaV</strong></li>
	local PWD=${PWD%<*} # remove text after last '<'
	# repeat only if extracting vpnbook password
	if [ "$USERNAME" = "vpnbook" ]
	then local PWD=${PWD%<*} 
	fi
	local PWD=${PWD##*>} # remove text before last '>'

	#remove Password: from string in case of vpnkeys service	
	if [ "$USERNAME" = "vpnkeys" ]
	then local PWD=${PWD##*:}
	fi
	
	PASSWORD=$PWD
	if [ -f $SAVE_TO ]
	then rm $SAVE_TO; 
	fi
	touch $SAVE_TO
	echo $USERNAME > $SAVE_TO # replace file and add username to first line
	echo $PWD >> $SAVE_TO # add password to new line
}


function ConnectProfile()
{
	DIR=$(pwd)
	L=$(echo $SELECTED_PROFILE | grep -c ".ovpn")
	if [ $L = "0" ]
	then
		INFO="Connection error! Profile not selected."
	else
		sudo openvpn --config "$DIR/$PROFILES_DIR/$SELECTED_PROFILE" --auth-user-pass "$DIR/$PROFILES_DIR/$PASSWORD_FILE"
		INFO="Disconnected from $SELECTED_PROFILE";
	fi
}

# usage: TestPortOut port tcp/udp / returns 1 if port is open
function TestPortOut()
{
	Port="$1"
	NC=""
	if [ "$2" = "udp" ]
	then netcat -z -u -v -q 2 -w 2 portquiz.net $Port &> /dev/null; NC=$?
	else netcat -z -v -q 2 -w 2 portquiz.net $Port &> /dev/null; NC=$?
	fi
	
	if [ $NC -eq 0 ]
	then return 1 #open
	else return 0 #closed
	fi
}

#############################################
#############################################
### MAIN MENU FUNCTIONS #####################
#############################################

function MENU_SelectProfile()
{
	DIR=$(pwd)
	CLS
	PrintTopMenuInfo
	echo "$(ChangeColor orange text)SELECT VPN PROFILE$(ChangeColor white text)"
	echo "––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––"
	cd "$DIR/$PROFILES_DIR"
	PROFILES=$(ls *.ovpn)
	HAVE_PROFILES=$?
	cd $DIR
	if [ "$HAVE_PROFILES" = "2" ]
	then INFO="No profiles available! Download profiles!"; PASSWORD=""; USERNAME=""; return
	fi
	
	select opt in $PROFILES; do
		SELECTED_PROFILE=$opt
		INFO="Profile selected: $opt"
		break
	done
	
	PROVIDER=""
	VPNBOOK=$(echo $SELECTED_PROFILE | grep -c "vpnbook")
	if [ $VPNBOOK = "1" ]; then PROVIDER="vpnbook";  fi

	VPNME=$(echo $SELECTED_PROFILE | grep -c "FreeVPN")
	if [ $VPNME = "1" ]; then PROVIDER="freevpnme";  fi

	VPNKEY=$(echo $SELECTED_PROFILE | grep -c "vpnkeys")
	if [ $VPNKEY = "1" ]; then PROVIDER="vpnkeys";  fi


	echo "WAIT! Reading password from web ..."
	
	# update password for selected profile
	case "$PROVIDER" in
		"vpnbook") UpdatePassword $URL_VPNBOOK $USER_BOOK; break
		;;
		"freevpnme") UpdatePassword $URL_FREEVPNME $USER_ME; break
		;;
		"vpnkeys") UpdatePassword $URL_VPNKEYS $USER_KEYS; break
		;;
		*) INFO="No profile selected!"; PASSWORD=""; USERNAME=""; return
		;;
	esac
	INFO="Password updated."
		
}

function MENU_DownloadProfiles()
{
	SERVICE_PROFILES=""
	SERVICE=""
	SERVICES="VPNbook.com FreeVPN.me VPNkeys.com"
	CLS
	PrintTopMenuInfo
	echo "$(ChangeColor orange text)DOWNLOAD VPN PROFILES$(ChangeColor white text)"
	echo "––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––"

	select opt in $SERVICES; do
		SERVICE=$opt
		case $opt in
			"VPNbook.com") SERVICE_PROFILES=$URL_VPNBOOK_PROFILES; break
			;;
			"FreeVPN.me") SERVICE_PROFILES=$URL_FREEVPNME_PROFILES; break
			;;
			"VPNkeys.com") SERVICE_PROFILES=$URL_VPNKEYS_PROFILES; break
			;;
			*) INFO="No service selected for download"; return
			;;
		esac
	done


	CLS
	PrintTopMenuInfo
	echo "$(ChangeColor orange text)DOWNLOAD $SERVICE PROFILES$(ChangeColor white text)"
	echo "––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––"

	select opt in $SERVICE_PROFILES; do
		DownloadProfile $opt
		break
	done

	
}

function MENU_Credits()
{
	local SELECT="Licence Back"
	CLS
	PrintTopMenuInfo
	echo "$(ChangeColor orange text)CREDITS$(ChangeColor white text)"
	echo "––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––"
	echo "Author of script: Sebastijan Bandur"
	echo "Authors email: seba.bandur@gmail.com"
	echo "Licence: GPL v2"
	echo "Powered by free VPN services: www.VPNbook.com www.FreeVPN.me www.VPNkeys.com"
	echo "Please DONATE to www.VPNbook.com www.FreeVPN.me www.VPNkeys.com"
	echo "––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––"
	select opt in $SELECT; do
		case $opt in
			"Licence") CLS; cat Licence.txt; echo ""
				select o in "Back"; do
					return
				done
			;;
			*) return
			;;
		esac
	done

}
function MENU_Help()
{
	local SELECT="Back"
	CLS
	PrintTopMenuInfo
	echo "$(ChangeColor orange text)HELP$(ChangeColor white text)"
	echo "––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––"
	cat Help.txt;  echo ""
	select opt in $SELECT; do
		return
	done

}

function MENU_Install()
{
	local OK_DEB=""
	local OK_RPM=""
	local SELECTED=""
	local SELECT="Deb Rpm Back"
	CLS
	PrintTopMenuInfo
	echo "$(ChangeColor orange text)OpenVPN INSTALATION. Select your package type: Rpm/Deb$(ChangeColor white text)"
	echo "––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––"
	select sel in $SELECT; do
		SELECTED=$sel
		case "$sel" in
			"Rpm")OK_RPM=$(rpm -qa | grep -c openvpn); break
			;;
			"Deb")OK_DEB=$(dpkg -s openvpn | grep Status | grep -c "installed"); break
			;;
			*) return
			;;
		esac
	done

	if [ $SELECTED = "Deb" ]
	then 
		if [ $OK_DEB = "1" ]
		then INFO="OpenVPN is alredy installed!"; return
		fi
	fi
	if [ $SELECTED = "Rpm" ]
	then 
		if [ $OK_RPM = "1" ]
		then INFO="OpenVPN is alredy installed!"; return
		fi
	fi


	SEL="Install Back"
	CLS
	PrintTopMenuInfo
	echo "$(ChangeColor orange text)INSTALL OpenVPN$(ChangeColor white text)"
	echo "––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––"
	select opt in $SEL; do
		if [ $opt = "Install" ]
		then
			if [ $SELECTED = "Deb" ]
			then sudo apt-get install openvpn
			else sudo yum install openvpn
			fi
			 INFO="OpenVPN is now installed."
		else
			return
		fi
		break
	done

}
function MENU_TestPort()
{
	PORT=""
	STATUS=""
	CONN=""
	MENU="tcp udp Back"
	while true; do
		CLS
		PrintTopMenuInfo
		echo "$(ChangeColor blue text)TEST OUTGOING PORTS$(ChangeColor white text)"
		echo "––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––"
		echo "$(ChangeColor red text)Port: $CONN $PORT $STATUS$(ChangeColor white text)"
		echo "––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––"
		select sel in $MENU;
		do
			if [ "$sel" = "Back" ] 
			then return
			fi
			read -p "Enter port $sel 1-65535 or range >from-to<: " PORT
			IS_RANGE=$( echo $PORT | grep -c "-" )
			
			if [ $IS_RANGE -eq 1 ]
			then
				STATUS="range tested"
				RANGE_STOP=${PORT##*-} # remove text before last '-'
				RANGE_STOP=$(echo $RANGE_STOP | tr -d "-")
				RANGE_START=${PORT%-*} # remove text after last '-'
				RANGE_START=$(echo $RANGE_START | tr -d "-")
				TIMEOUT=""
				read -p "Enter timeout in seconds: " TIMEOUT
				echo "Testing $sel ports from $RANGE_START to $RANGE_STOP with $TIMEOUT timeout ..."
				i=$RANGE_START
				
				while [ $i -le $RANGE_STOP ]
				do
					TestPortOut $i $sel
					S=$?
					if [ $S -eq 1 ]
					then S="$(ChangeColor green text)Port $sel $i Open$(ChangeColor white text)"
					else S="$(ChangeColor red text)Port $sel $i Closed$(ChangeColor white text)"
					fi
					echo "$S"
					i=$((i+1))
				done
				
				read -p "Enter to continue"
			else				
				TestPortOut $PORT $sel
				STATUS=$?
				if [ $STATUS -eq 1 ]
				then STATUS="$(ChangeColor green text)Open$(ChangeColor white text)"
				else STATUS="Closed"
				fi
				
			fi
			CONN=$sel
			break
		done
	done
}
###########################################################################################
############################ MAIN MENU SELECTION ##########################################
###########################################################################################
CLS
MENU_ITEMS="Profile Connect Download Clean Ports Install Credits Help Quit"
while true
do
	if [ $INFO = "" ]
	then	INFO=$IMPORTANT
	fi

	CLS
	PrintTopMenuInfo
	echo "Profile:  $(ChangeColor blue text)$SELECTED_PROFILE$(ChangeColor white text)"
	echo "Username: $(ChangeColor orange text)$USERNAME$(ChangeColor white text)"
	echo "Password: $(ChangeColor orange text)$PASSWORD$(ChangeColor white text)"
	echo "––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––"
	echo "INFO: $(ChangeColor red text)$INFO$(ChangeColor white text)"
	echo "––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––"
	select menu in $MENU_ITEMS; do
		case "$menu" in
			"Profile") INFO=""; MENU_SelectProfile; break
			;;
			"Connect") INFO=""; ConnectProfile; break
			;;
			"Download") INFO=""; MENU_DownloadProfiles; break
			;;
			"Clean") INFO=""; ClearProfiles; break
			;;
			"Ports") INFO=""; MENU_TestPort; break
			;;
			"Install") INFO=""; MENU_Install; break
			;;
			"Credits") INFO=""; MENU_Credits; break
			;;
			"Help") INFO=""; MENU_Help; break
			;;
			"Quit") echo "Quiting Free VPN Connect..."; CLS; break 2
			;;
			*) INFO="Wrong selection!"; break
			;;
		esac
	done
done

