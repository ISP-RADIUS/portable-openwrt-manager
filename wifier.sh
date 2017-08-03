#!/bin/sh

#Author: marcocspc
#Feel free to modify, improve and distribute!


### DO NOT FORGET TO MODIFY THESE VARS TO MATCH YOUR ROUTER CONFIG ###

DIR="/etc/wifier" #create this dir mannually
STA_INTERFACE="@wifi-iface[0]" #to discover which is you sta interface, use 'uci show wireless | grep sta' 
WLAN_INTERFACE="wlan0" #generally this option is the default for everyone

#THE AREA BELOW IS RESERVED FOR DEVELOPERS :P
#EDIT ONLY IF YOU KNOW WHAT YOU ARE DOING!

CONFIRM_YES="-y"

case $1 in	
	disable-sta)
		
		#disables the sta interface
		#you can put this command inside rc.local, so every time your PORTABLE router boots
		#you will be able to connect to it via wifi
		
		uci set wireless.$STA_INTERFACE.disabled='1'
		uci commit
		wifi
		
	;;
	scan)
	
		#got code from https://forum.openwrt.org/viewtopic.php?id=39485 and modified it
		#the great part about this code is that is doesn't turn wifi off while it is being executed
		#so you can view the results withou losing the connection
		
		iwlist $WLAN_INTERFACE scanning > /tmp/wifiscan #save scan results to a temp file
		scan_ok=$(grep "wlan" /tmp/wifiscan) #check if the scanning was ok with WLAN_INTERFACE
		
		if [ -z "$scan_ok" ]; then
		    iwlist $WLAN_INTERFACE-1 scanning > /tmp/wifiscan
		fi
		scan_ok=$(grep "wlan" /tmp/wifiscan) #check if the scanning was ok
		if [ -z "$scan_ok" ]; then #if scan was not ok, finish the script
		    echo -n "
		WIFI scanning failed.
		    
		"
		    exit
		fi
		if [ -f /tmp/ssids ]; then
		    rm /tmp/ssids
		fi
		n_results=$(grep -c "ESSID:" /tmp/wifiscan) #save number of scanned cell
		i=1
		while [ "$i" -le "$n_results" ]; do
		        if [ $i -lt 10 ]; then
					cell=$(echo "Cell 0$i - Address:")
		        else
					cell=$(echo "Cell $i - Address:")
		        fi
		        j=`expr $i + 1`
		        if [ $j -lt 10 ]; then
		                nextcell=$(echo "Cell 0$j - Address:")
		        else
		                nextcell=$(echo "Cell $j - Address:")
		        fi
		        awk -v v1="$cell" '$0 ~ v1 {p=1}p' /tmp/wifiscan | awk -v v2="$nextcell" '$0 ~ v2 {exit}1' > /tmp/onecell #store only one cell info in a temp file
		
		        ##################################################
		        ## Uncomment following line to show mac address ##
		
		        oneaddress=$(grep " Address:" /tmp/onecell | awk '{print $5}')
		
		        onessid=$(grep "ESSID:" /tmp/onecell | awk '{ sub(/^[ \t]+/, ""); print }' | awk '{gsub("ESSID:", "");print}')
		        oneencryption=$(grep "Encryption key:" /tmp/onecell | awk '{ sub(/^[ \t]+/, ""); print }' | awk '{gsub("Encryption key:on", "(secure)");print}' | awk '{gsub("Encryption key:off", "(open)  ");print}')
		        onepower=$(grep "Quality=" /tmp/onecell | awk '{ sub(/^[ \t]+/, ""); print }' | awk '{gsub("Quality=", "");print}' | awk -F '/70' '{print $1}')
		        onepower=$(awk -v v3=$onepower 'BEGIN{ print v3 * 10 / 7}')
		        onepower=${onepower%.*}
		        onepower="(Signal strength: $onepower%)"
		        if [ -n "$oneaddress" ]; then                                                                                                            
		                echo "$onessid  $oneaddress $oneencryption $onepower" >> /tmp/ssids                                                              
		        else                                                                                                                                     
		                echo "$onessid  $oneencryption $onepower" >> /tmp/ssids                                                                          
		        fi
		        i=`expr $i + 1`
		done
		rm /tmp/onecell
		awk '{printf("%5d : %s\n", NR,$0)}' /tmp/ssids > /tmp/sec_ssids #add numbers at beginning of line
		grep ESSID /tmp/wifiscan | awk '{ sub(/^[ \t]+/, ""); print }' | awk '{printf("%5d : %s\n", NR,$0)}' | awk '{gsub("ESSID:", "");print}' > /tmp/ssids #generate file with only numbers and names
		echo -n "Available WIFI networks:"
		echo ""
		cat /tmp/sec_ssids #show ssids list
		
		
	;;
	save)
	
		#save current profile as $2
		if [[ '$3' == '$CONFIRM_YES' ]]; then
			echo "Saving..."
			FILE="$DIR/$2.prof"
			echo "#!/bin/sh" >> $FILE
			echo"" >> $FILE
			SSID="$(uci get wireless."$STA_INTERFACE".ssid)"
			echo "uci set wireless.$STA_INTERFACE.ssid='$SSID'" >> $FILE
			ENCRYPTION="$(uci get wireless."$STA_INTERFACE".encryption)"
			echo "uci set wireless.$STA_INTERFACE.encryption='$ENCRYPTION'" >> $FILE
			BSSID="$(uci get wireless."$STA_INTERFACE".bssid)"
			echo "uci set wireless.$STA_INTERFACE.bssid='$BSSID'" >> $FILE
			KEY="$(uci get wireless."$STA_INTERFACE".key)"
			echo "uci set wireless.$STA_INTERFACE.key='$KEY'" >> $FILE
			echo "uci commit" >> $FILE
			echo "Done!"
			
			chmod 700 $FILE
		else
			while true; do
				echo "I will save the current WWAN configuration as $2.prof."
				read -p "Is that correct? [y/n] " yn
				case $yn in
					[Yy]*)
						echo "Saving..."
						FILE="$DIR/$2.prof"
						echo "#!/bin/sh" >> $FILE
						echo"" >> $FILE
						SSID="$(uci get wireless."$STA_INTERFACE".ssid)"
						echo "uci set wireless.$STA_INTERFACE.ssid='$SSID'" >> $FILE
						ENCRYPTION="$(uci get wireless."$STA_INTERFACE".encryption)"
						echo "uci set wireless.$STA_INTERFACE.encryption='$ENCRYPTION'" >> $FILE
						BSSID="$(uci get wireless."$STA_INTERFACE".bssid)"
						echo "uci set wireless.$STA_INTERFACE.bssid='$BSSID'" >> $FILE
						KEY="$(uci get wireless."$STA_INTERFACE".key)"
						echo "uci set wireless.$STA_INTERFACE.key='$KEY'" >> $FILE
						echo "uci commit" >> $FILE
						echo "Done!"
						
						chmod 700 $FILE
						
						break
					;;
					[Nn]*)
						echo "Bye."
						break
					;;
					*)
						echo "Please enter Y or N."
					;;
				esac	
			done
		fi
			
		
	;;
	list)
		
		#list available profiles
		PROFILE_LIST=$(ls $DIR | sed -e "s/\.prof//g")
		echo "Available profiles:"
		echo ""
		echo $PROFILE_LIST
		
	;;
	load)
	
		#load $2 profile
		if [[ '$3' == '$CONFIRM_YES' ]]; then
			$DIR/$2.prof
			echo "Done!"
		else
			echo "I will load the WLAN configuration named $2.prof. If your sta interface is off, you will"
			echo "have to manually turn it on via UCI or via LUCI web interface."
			read -p "Is that correct? [y/n] " yn
			case $yn in
				[Yy]*)
					$DIR/$2.prof
					echo "Done!"
					break
				;;
				[Nn]*)
					echo "Bye."
					break
				;;
				*)
					echo "Please enter Y or N."
				;;
			esac
		fi
	;;
	*)
		echo "Please use only 'disable-sta', 'scan', 'save <profile-name>', 'load <profile-name>' or 'list'."
		echo "If you want to force any option, without being prompted for 'yes' or 'no', please use '$CONFIRM_YES'."
	;;
esac
