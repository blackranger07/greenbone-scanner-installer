#!/usr/bin/bash

#******************************************************
#    GSA Scanner Suite Installer - Kali Linux Only    *
# Created By: BlackRanger07                           *
# Date: October 3, 2022                               *
#******************************************************

clear 

#Verify that the user is root before continuing.
ID=$(/usr/bin/id -u)
if [ ${ID} -ne 0 ] && [ whoami != "root" ]; then
	echo "You don't possess the power of Root!"
	echo "You must be Root to run the Installer. Try sudo su"
	exit 1
fi

upgrade_postgresql () {
	#List all of the postgresql clusters
	pg_lsclusters
	echo ""
	read -p "Which version would you like to drop? (Ex: 14 or 15) Usually the later version. " VERSION
	#Dropping the newer version data.
	pg_dropcluster --stop ${VERSION} main
	if [ $? == 0 ]; then
		#Start the upgradecluster procedure.
		read -p "Which cluster version to upgrade?" VERSION
		pg_upgradecluster ${VERSION} main
		if [ $? == 0 ]; then
			echo "Which version should be deleted? (Ex: 14 or 15) Usually the later version " VERSION
			echo "Continue with removing the old version? (y/N) " CHOICE
			if [ ${CHOICE} == "Y" ] || [ ${CHOICE} == "y" ]; then
				pg_dropcluster --stop ${VERSION} main
			fi
		fi	
	fi 
	Trouble_Shoot
}

migrate_postgresql() {
	systemctl daemon-reload
	if [ $? == 0 ]; then
		echo "Creating Postgresql database"
		runuser -u postgres -- /usr/share/gvm/create-postgresql-database
		if [ $? == 0 ]; then
			echo "Postgresql database created successfully"
			read -p "Continue with migrating postgresql? (y/N) " MENU
			if [ ${MENU} == "Y" ] || [ ${MENU} == "y" ]; then
				runuser -u _gvm -- gvmd --migrate
			else
				echo "Postgresql Migration abandoned."
				exit 1
			fi
		else
			echo "There was an issue with creating Postgresql database. Run gvm-check-setup."
			sleep 4
			exit 1
		fi
	fi
	Trouble_Shoot
}

Trouble_Shoot () {
	clear
	#For trouble shooting various issues with Greenbone.
	printf '%s\n' \
	'#****************************************************' \
	'         GSA Scanner Suite - TroubleShooter   ' \
	"* (1) - Upgrade Postgresql" \
	"* (2) - Migrate Postgresql database to new version" \
	"* (3) - Check GVM Setup" \
	"* (E) - Exit" \
	'         Created By: BlackRanger07   ' \
	'#****************************************************' \

	echo ""
	read -p "Make your choice from the above menu: " MENU
	echo ""

	if [ ${MENU} == "1" ]; then
		upgrade_postgresql
	elif [ ${MENU} == "2" ]; then
		migrate_postgresql
	elif [ ${MENU} == "3" ]; then
		gvm-check-setup
	elif [ ${MENU} == "E" ] || [ ${MENU} == "e" ]; then
		echo "You've exited the program."
		exit 1
	fi
}

WEB_UI () {
	#Grant access for any device to reach web UI.
	GSAFILE="/usr/lib/systemd/system/greenbone-security-assistant.service"
	if [ ! -f ${GSAFILE} ]; then
		echo "Greenbone-Security-Assistant.service Does Not Exist. Install GSA with option (1) then return."
		sleep 5
	elif [ -f ${GSAFILE} ]; then
		gvm-stop
		sed -i 's/127.0.0.1/0.0.0.0/g' ${GSAFILE}
	fi
	if [ $? == 0 ]; then
	   	#Restart daemon
	   	systemctl daemon-reload
	   	if [ $? == 0 ]; then
	   		echo "Changes have been made successfully."
	   		sleep 7
	   	fi
	fi
}

INSTALL_GSA () {
	read -p "Proceed with Greenbone Security Agent Installation (y/N)? " CHOICE

	if [ ${CHOICE} == "y" ] || [ ${CHOICE} == "Y" ]; then
		#Verify Internet Connectivity...
		ping -c 1 8.8.8.8 > /dev/null 2>&1
		if [ $? == 0 ]; then
			#Update and upgrade the system.
			read -p "Update system (y/N)? " CHOICE
			if [ ${CHOICE} == "y" ] || [ ${CHOICE} == "Y" ]; then
				apt-get update -y && apt-get upgrade -y
			fi
			if [ $? == 0 ]; then
				#Make any prerequisite installs/changes
				systemctl start ssh
				VIM=`which vim 2> /dev/null`
				if [ ${VIM} ]; then
					echo "EXISTS" > /dev/null
				else
					apt-get install vim -y # IF any other programs are needed, add on same line.
				fi
				if [ $? == 0 ]; then
					#Install OpenVAS
					clear
					echo "Installing OpenVAS"
					sleep 1.5
					apt-get install openvas -y
					if [ $? == 0 ]; then
						#Install GVM
						clear
						echo "Installing GVM, this will take at least 30 mins to complete..."
						sleep 1.5
						touch /opt/gvm-setup-log.txt
						touch /opt/gvm-pass.txt
						gvm-setup >> /opt/gvm-setup-log.txt
						grep "User created with password" /opt/gvm-setup-log.txt | awk '{print $6}' | cut -d "." -f 1 | sort -u > /opt/gvm-pass.txt
						gvm-check-setup #Checks to ensure install was successful.
						if [ $? == 0 ]; then
							#Install Security Feeds
							greenbone-feed-sync —type GVMD_DATA
							greenbone-feed-sync —type SCAP
							greenbone-feed-sync —type CERT
							gvm-stop
						fi
	                    if [ $? == 0 ]; then
	                    	gvm-feed-update
	                    	gvm-start
	                    fi
	                    clear
						echo "Copy the admin password below, without it you will not be able to login to OpenVAS GSA."
	                    cat /opt/gvm-pass.txt
	                    exit 1
	                    #ERASE files in /opt afterwards...
					fi
				else
					echo "There was an error installing OpenVAS. Please Investigate."
					exit 1
				fi
			else
				echo "Update or upgrade was unable to complete."
				exit 1
			fi
		else
			echo "Unable to access the Internet, please check network configuration and try again."
			exit 1
		fi
	else
		echo "Installation was abandoned."
		exit 1
	fi
}

while [ 1 == 1 ]; do
	clear

	printf '%s\n' \
	'#****************************************************' \
	'         GSA Scanner Suite - Kali Linux   ' \
	"* (1) - Install GSA Vulnerability Scanner" \
	"* (2) - Update GSA Feed and Start GSA" \
	"* (3) - Grant access for any device to reach WEB UI" \
	"* (4) - TroubleShooting" \
	"* (E) - Exit" \
	'         Created By: BlackRanger07   ' \
	'#****************************************************' \

	echo ""
	read -p "Make your choice from the above menu: " MENU
	echo ""

	if [ ${MENU} == "1" ]; then
		INSTALL_GSA
	elif [ ${MENU} == "2" ]; then
		gvm-feed-update && gvm-start
	elif [ ${MENU} == "3" ]; then
		WEB_UI
	elif [ ${MENU} == "4" ]; then
		Trouble_Shoot
	elif [ ${MENU} == "E" ] || [ ${MENU} == "e" ]; then
		echo "You've exited the program."
		exit 1
	elif [ ${MENU} != "1" ] || [ ${MENU} != "2"  ] || [ ${MENU} != "3" ] || [ ${MENU} != "4" || [ ${MENU} != "E" || [ ${MENU} != "e" ]; then
		echo "Invalid input, please try again."
		sleep 2
	fi
done