#!/bin/bash

# NOTES ====================================================
# ==========================================================
#
# Need to add a 'routes' section to the network-config file?
# e.g.
# routes:
#   - to: 0.0.0.0/0
#     via: 10.0.1.1
#
# Need to correct the SUBNET calculations, the nameservers, and the gateways?
#
# Need to correct docker install?
# 
# Need to correct /etc/hosts addition for ports.ubuntu.com?
#
# Options for the usercfg.txt
#
# over_voltage=5
# arm_freq=1800
# force_turbo=1
# gpu_mem=16
# gpu_freq=300
# dtoverlay=disable-bt
# dtoverlay=disable-wifi
#

# Unmount any SD cards
SDCARD_MOUNTS=$(mount | grep -c mmc)
if [ "$SDCARD_MOUNTS" -ne "0" ]; then
	echo "------ Unmounting the SDCard partitions"
	MOUNTED_SDPARTITIONS=$(mount | grep mmc | cut -d' ' -f1)
	while IFS= read -r partition; do
		sudo umount $partition
	done <<< "$MOUNTED_SDPARTITIONS"
fi

# Get the hostname parameter
HOSTNAME=""
if [[ $# < 2 ]]; then
	echo "YOU MUST SUPPLY A HOSTNAME"
	echo $0" hostname ip-address [writeSD]"
	exit 1
else
	HOSTNAME=$1
	echo "------ Hostname =   "$HOSTNAME
fi

# Get the ip-address parameter
IP_ADDRESS_TO_REGISTER=""
DESIRED_IP_ADDRESS=$2
echo "------ Desired IP = "$DESIRED_IP_ADDRESS
CURRENT_SUBNET=$(echo $DESIRED_IP_ADDRESS | cut -d'.' -f1-3)
echo "------ Subnet =     "$CURRENT_SUBNET
FILTER_SUBNET=$(echo $CURRENT_SUBNET. | sed 's/\./\\\./g')

# Make sure this is the correct ip-address
DESIRED_IP_MATCHES_SUBNET=$(echo $DESIRED_IP_ADDRESS | grep -c $FILTER_SUBNET)
if [ "$DESIRED_IP_MATCHES_SUBNET" -eq "0" ]; then
	echo ""
	echo "###  You are attempting to assign an IP Address that is not in the current subnet"
	echo "###  Desired IP Address : " $DESIRED_IP_ADDRESS
	echo "###  Current Subnet     : " $CURRENT_SUBNET
	while true
	do
		read -p "###  ARE YOU SURE YOU WANT TO ASSIGN THIS IP ADDRESS [Y/n] ?" answer
		case $answer in
			[yY]* ) break;;
			[nN]* ) exit;;
			* ) echo "###  Please supply a Y or an N..."
		esac
	done
	IP_ADDRESS_TO_REGISTER=$DESIRED_IP_ADDRESS
else
	echo "> making sure the IP Address is not taken"
	IP_ADDRESSES_IN_USE=$(nmap -sn $CURRENT_SUBNET.0/24 | grep $FILTER_SUBNET | rev |  cut -d' ' -f1 | rev | sed 's/[()]//g')
	DESIRED_IP_TAKEN=$(echo $IP_ADDRESSES_IN_USE | grep -c $DESIRED_IP_ADDRESS)
	if [ "$DESIRED_IP_TAKEN" -eq "1" ]; then
		#IP_ADDRESS_LIST=($(echo $IP_ADDRESSES_IN_USE | tr " " "\n"))
		#LAST_ADDRESS_INDEX=${#IP_ADDRESS_LIST[@]}
		#LAST_ADDRESS_INDEX=$((--LAST_ADDRESS_INDEX))
		#LAST_OCTAL_OF_LAST_IP_ADDRESS=$(echo ${IP_ADDRESS_LIST[LAST_ADDRESS_INDEX]} | cut -d'.' -f4)
		#NEXT_IP_ADDRESS=$CURRENT_SUBNET.$((LAST_OCTAL_OF_LAST_IP_ADDRESS+1))
		echo ""
		echo "###  The IP Address you are attempting to assign is already taken"
		echo "###  Desired IP Address     : " $DESIRED_IP_ADDRESS
		echo "###  Recommended IP Address : " $NEXT_IP_ADDRESS
		echo "###  Current Subnet         : " $CURRENT_SUBNET
		echo "###  Are you sure you want to use the desired IP Address?"
		while true
		do
			read -p "###  ENTER 'Y' TO USE THE DESIRED IP ADDRESS, ENTER 'N' TO USE THE RECOMMENDED IP ADDRESS" answer
			case $answer in
				[yY]* ) IP_ADDRESS_TO_REGISTER=$DESIRED_IP_ADDRESS
					break;;
				[nN]* ) IP_ADDRESS_TO_REGISTER=$NEXT_IP_ADDRESS
					break;;
				*) echo "###  Please supply a Y or an N..."
			esac
		done
	else
		IP_ADDRESS_TO_REGISTER=$DESIRED_IP_ADDRESS
	fi
fi
echo "------ IP Address = "$IP_ADDRESS_TO_REGISTER

# Check if we are writing the SDCard
if [[ $# > 2 ]]; then
	WRITE_SD=$(echo $3 | grep -c 'writeSD')

	if [[ "$WRITE_SD" -eq "1" ]]; then
		echo "------ Writing Ubuntu 22.04 LTS to the SDCard"
		xzcat ubuntu-22.04.3-preinstalled-server-arm64+raspi.img.xz | sudo dd of=/dev/mmcblk0 bs=4M status=progress conv=fsync; sync
		sleep 60s
	fi
fi

# Mount the SD Card partitions in specified locations
echo "------ Mounting the SDCard partiions"
sudo mount /dev/mmcblk0p1 ./boot
sudo mount /dev/mmcblk0p2 ./root

# Set the hostname
echo $HOSTNAME | sudo tee root/etc/hostname

# Enable virtualization
CGROUP_ADDED=$(cat boot/cmdline.txt | grep -c cgroup)
if [ "$CGROUP_ADDED" -eq "0" ]; then
	echo "------ Enabling Virtualization"
	sudo sed -i 's/^/cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory /' boot/cmdline.txt
else
	echo "> Virtualization already enabled"
fi

# Disable WiFi and Bluetooth
WIFI_DISABLED=$(cat boot/usercfg.txt | grep -c disable-wifi)
BT_DISABLED=$(cat boot/usercfg.txt | grep -c disable-bt)
if [ "$WIFI_DISABLED" -eq "0" ]; then
	echo "------ Disabling WiFi"
	echo "dtoverlay=disable-wifi" | sudo tee -a boot/usercfg.txt
else
	echo "> WiFi already disabled"
fi
if [ "$BT_DISABLED" -eq "0" ]; then
	echo "------ Disabling Bluetooth"
	echo "dtoverlay=disable-bt" | sudo tee -a boot/usercfg.txt
else
	echo "> Bluetooth already disabled"
fi

# Create the static IP Address for this device
# Update the netplan network configuration to include the static ip address
STATIC_IP_ALREADY_SET=$(sudo yq e '.network.ethernets.eth0.addresses' boot/network-config )
if [ "$STATIC_IP_ALREADY_SET" = "null" ]; then
	echo "------ Setting the static IP Address to : " $IP_ADDRESS_TO_REGISTER

	sudo yq e -i '.network.ethernets.eth0.addresses[0] = "'$IP_ADDRESS_TO_REGISTER'/24"' boot/network-config 
	sudo yq e -i '.network.ethernets.eth0.dhcp4 = false' boot/network-config 
	sudo yq e -i '.network.ethernets.eth0.gateway4 = "'$CURRENT_SUBNET'.1"' boot/network-config
	sudo yq e -i '.network.ethernets.eth0.nameservers.addresses[0] = "8.8.8.8"' boot/network-config 
	sudo yq e -i '.network.ethernets.eth0.nameservers.addresses[1] = "10.0.0.254"' boot/network-config 

	# For some reason, this 'netplan' strategy does not work correctly, 
	# so we are going to modify the command-line to force a static IP
	sudo sed -i 's@$@ ip='"$IP_ADDRESS_TO_REGISTER"'::'"$CURRENT_SUBNET"'.1:255.255.255.0:'"$HOSTNAME"':eth0:off@' boot/cmdline.txt

	# We also need to hard-code the DNS nameservers into systemd resolver config
	sudo mkdir -p ./root/etc/systemd/resolved.conf.d/
	echo "[Resolve]" | sudo tee ./root/etc/systemd/resolved.conf.d/dns_servers.conf
	echo "DNS=10.0.0.254" | sudo tee -a ./root/etc/systemd/resolved.conf.d/dns_servers.conf
else
	echo "> Static IP already set to " $STATIC_IP_ALREADY_SET
fi



# Setup the user profile on the SDCard
#sudo cp -f user-data boot/user-data
#USER_ID=1000
#USER_PROFILE=clusteradm
#USER_PASSWORD="password"
#USER_PROFILE_FOLDER="root/home/$USER_PROFILE"
#if [ ! -d $USER_PROFILE_FOLDER ]; then
#	echo "------ Creating Cluster Admin user profile"
#	sudo cp -av root/etc/skel $USER_PROFILE_FOLDER
#	sudo chmod -R o-rw $USER_PROFILE_FOLDER
#	
#	sudo touch boot/ssh
#	sudo mkdir -p $USER_PROFILE_FOLDER/.ssh
#	sudo cp ~/.ssh/id_rsa.pub $USER_PROFILE_FOLDER/.ssh/authorized_keys
#	sudo chmod 644 $USER_PROFILE_FOLDER/.ssh/authorized_keys
#	
#	sudo chown -R "$USER_ID:$USER_ID" $USER_PROFILE_FOLDER
#else
#	echo "> Cluster Admin user profile already created"
#fi

#SSH_PASSWORDS_DISABLED=$(cat /etc/ssh/sshd_config | grep -c 'PasswordAuthentication yes')
#if [[ $SSH_PASSWORDS_DISABLED = 1 ]]; then
#	echo "------ Disabling passwords for SSH"
#	sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
#else
#	echo "> Password auth for SSH already disabled"
#fi


#USER_ACCOUNT_CREATED=$(sudo grep -c $USER_PROFILE root/etc/shadow)
#if [ "$USER_ACCOUNT_CREATED" -eq "0" ]; then
#	echo "------ Creating Cluster Admin login"
#	PASSWD=$(openssl passwd -6 -salt saltsalt $USER_PASSWORD)
#	echo "$USER_PROFILE:$PASSWD:18474:0:999999:7::::" | sudo tee -a root/etc/shadow
#	echo "$USER_PROFILE:x:$USER_ID:$USER_ID:Cluster Admin,,,:/home/$USER_PROFILE:/bin/bash" | sudo tee -a root/etc/passwd
#	echo "$USER_PROFILE:x:$USER_ID:" | sudo tee -a root/etc/group
#else
#	echo "> Cluster Admin login already created"
#fi

#Unmount the SD Card partitions
echo "------ Unmounting the SDCard partitions"
sudo umount ./boot
sudo umount ./root
