#!/usr/bin/env bash


# CREATOR: Mike Lu (klu7@lenovo.com)
# CHANGE DATE: 2/24/2025
__version__="1.0"


# Ubuntu Hardware Certification Test Environment Setup Script



# User-defined settings
TIME_ZONE='Asia/Taipei'
TC_internal_IP='192.168.20.1'
TC_internal_netmask='24'


# Fixed settings
red='\e[41m'
green='\e[32m'
yellow='\e[93m'
nc='\e[0m'


# Ensure the user is running the script as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${yellow}Please run as root (sudo su) to start the installation.${nc}"
    exit 1
fi


# Customize keyboard shortcut
OS_VER=`cat /etc/os-release | grep ^VERSION_ID= | awk -F= '{print $2}' | cut -d '"' -f2`
USERNAME=$(logname)
ID=`id -u $USERNAME`
sudo -H -u $USERNAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID/bus gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/','/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']"


# Open Current folder (Super+E)
sudo -H -u $USERNAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID/bus gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'Current folder' 
sudo -H -u $USERNAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID/bus gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'nautilus .' 
sudo -H -u $USERNAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID/bus gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<super>e' 


# Open Settings (Super+I)
sudo -H -u $USERNAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID/bus gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ name 'Settings' 
sudo -H -u $USERNAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID/bus gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ command 'gnome-control-center' 
sudo -H -u $USERNAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID/bus gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ binding '<super>i'


# Set proxy to automatic
sudo -H -u $USERNAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID/bus gsettings set org.gnome.system.proxy mode 'auto' 2> /dev/null


# Disable auto suspend/dim screen/screen blank/auto power-saver
sudo -H -u $USERNAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID/bus gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type "nothing" 2> /dev/null
sudo -H -u $USERNAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID/bus gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type "nothing" 2> /dev/null
sudo -H -u $USERNAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID/bus gsettings set org.gnome.settings-daemon.plugins.power idle-dim "false" 2> /dev/null
sudo -H -u $USERNAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID/bus gsettings set org.gnome.desktop.session idle-delay "0" > /dev/null 2> /dev/null
sudo -H -u $USERNAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID/bus gsettings set org.gnome.settings-daemon.plugins.power power-saver-profile-on-low-battery "false" 2> /dev/null


# Show battery percentage
sudo -H -u $USERNAME DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID/bus gsettings set org.gnome.desktop.interface show-battery-percentage "true" 2> /dev/null


# Set local time zone and reset NTP
timedatectl set-timezone $TIME_ZONE
ln -sf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime
timedatectl set-ntp 0 && sleep 1 && timedatectl set-ntp 1


# Enable auto login
NEW_USER=$(w | awk 'END {print $1}')
CONFIG_FILE="/etc/gdm3/custom.conf"
AUTOLOGIN_ENABLE=$(grep "^[^#\[]" "$CONFIG_FILE" | grep "AutomaticLoginEnable" | cut -d '=' -f 2)
if [[ -z "$AUTOLOGIN_ENABLE" ]]; then
    # AutomaticLoginEnable is not set, so enable it and set the new user
    sed -i "s/\[daemon\]/[daemon]\nAutomaticLoginEnable=True\nAutomaticLogin=${NEW_USER}/1" "$CONFIG_FILE"
    echo "Set user [$NEW_USER] to auto login and enabled AutomaticLoginEnable."
    echo -e "Need to reboot the system to take effect the change!\n"
elif [[ "$AUTOLOGIN_ENABLE" == "True" ]]; then
    # AutomaticLoginEnable is already enabled, so update the user
    CUR_USER=$(grep "^[^#\[]" "$CONFIG_FILE" | grep "AutomaticLogin=" | cut -d '=' -f 2)
    if [[ $CUR_USER != $NEW_USER ]]; then
        sed -i "s/AutomaticLogin=${CUR_USER}/AutomaticLogin=${NEW_USER}/1" "$CONFIG_FILE"
        echo "Changed auto login user from [$CUR_USER] to [$NEW_USER]."
        echo -e "Need to reboot the system to take effect the change!\n"
    fi
else
    # AutomaticLoginEnable is set to False, so enable it and set the new user
    sed -i "s/AutomaticLoginEnable=${AUTOLOGIN_ENABLE}/AutomaticLoginEnable=True/1" "$CONFIG_FILE"
    sed -i "s/AutomaticLogin=${CUR_USER}/AutomaticLogin=${NEW_USER}/1" "$CONFIG_FILE"
    echo "Set user [$NEW_USER] to auto login and enabled AutomaticLoginEnable."
    echo -e "Need to reboot the system to take effect the change!\n"
fi


# Ensure Internet is connected
CheckInternet() {
nslookup "google.com" > /dev/null
if [ $? != 0 ]; then 
    echo -e "${red}No Internet connection! Please check your network${nc}" && sleep 5 && exit 1
fi
}
CheckInternet


# Get system type from user
echo "╭─────────────────────────────────────────────────────╮"
echo "│    Ubuntu Certification Test Environment Setup      │"
echo "╰─────────────────────────────────────────────────────╯"
echo "Are you setting up a SUT or TC (MaaS)?"
read -p "(s)SUT   (t)TC: " TYPE
while [[ "$TYPE" != [SsTt] ]]; do 
read -p "(s)SUT   (t)TC: " TYPE
done   


#================ TC ===================
if [[ "$TYPE" == [Tt] ]]; then
    echo "Which OS version are you going to certify for SUT?"
    read -p "(1)24.04   (2)22.04: " SUT_OS_VER
    while [[ "$SUT_OS_VER" != [12] ]]; do 
        read -p "(1)24.04   (2)22.04: " SUT_OS_VER
    done
fi


# Set TC hostname
! hostname | grep 'master' > /dev/null && hostnamectl set-hostname 'master' 


# Configure TC network
echo
echo "----------------------------------"
echo "CONFIGURING TC LOCAL NETWORK IP..."
echo "----------------------------------"
echo
mapfile -t interfaces < <(ip a | awk '/^[0-9]+:/ {print $2}' | cut -d ':' -f 1 | grep -v 'lo')
if [ ${#interfaces[@]} -eq 0 ]; then
    echo -e "${red}No network interfaces found!${nc}"
    exit 1
fi

# Separate interfaces by cable state
up_interfaces=()
down_interfaces=()
for i in "${!interfaces[@]}"; do
    cable_state=$(ip link show ${interfaces[$i]} | grep -w "state" | awk '{print $9}')
    if [[ "$cable_state" == "UP" ]]; then
        up_interfaces+=("${interfaces[$i]}")
    else
        down_interfaces+=("${interfaces[$i]}")
    fi
done

# Sort interfaces with 'UP' first
sorted_interfaces=("${up_interfaces[@]}" "${down_interfaces[@]}")


# Display available network interfaces
echo -e "${yellow}Available network interfaces:${nc}"
for i in "${!sorted_interfaces[@]}"; do
    current_ip=$(ip addr show ${sorted_interfaces[$i]} | grep -w 'inet' | awk '{print $2}' | cut -d/ -f1)
    cable_state=$(ip link show ${sorted_interfaces[$i]} | grep -w "state" | awk '{print $9}')
    if [ -z "$current_ip" ]; then
        current_ip="n/a"
    fi
    printf "(%d) %-15s ip: %-15s state: %s\n" "$((i+1))" "${sorted_interfaces[$i]}" "$current_ip" "$cable_state"
done


# Ask users to select a network interface for 'external' connection
while true; do
    read -p "Select the *External* network device number: " selected_num_external
    if ! [[ "$selected_num_external" =~ ^[0-9]+$ ]]; then
        continue
    fi
    if [ "$selected_num_external" -ge 1 ] && [ "$selected_num_external" -le "${#sorted_interfaces[@]}" ]; then
        selected_NIC_external="${sorted_interfaces[$((selected_num_external-1))]}"
        break
    else
        continue
    fi
done
echo -e "${yellow}Selected device (External): $selected_NIC_external${nc}\n"


# Ask users to select a network interface for 'internal' connection
while true; do
    read -p "Select the *Internal* network device number: " selected_num_internal
    if ! [[ "$selected_num_internal" =~ ^[0-9]+$ ]]; then
        continue
    fi
    if [ "$selected_num_internal" -ge 1 ] && [ "$selected_num_internal" -le "${#sorted_interfaces[@]}" ]; then
        selected_NIC_internal="${sorted_interfaces[$((selected_num_internal-1))]}"
        break
    else
        continue
    fi
done
echo -e "${yellow}Selected device (Internal): $selected_NIC_internal${nc}\n"


# Enable the network connection for selected interface
nmcli device connect $selected_NIC_internal > /dev/null 2>&1 &
connect_pid=$!
sleep 2

# Get connection name from the selected interface
connection_name=$(nmcli device show $selected_NIC_internal | grep "GENERAL.CONNECTION" | awk '{$1=""; sub(/^ */, ""); gsub(/[[:space:]]*$/, ""); print}') 

# Set internal IP and netmask 
if ! nmcli connection modify "$connection_name" ipv4.method manual ipv4.addresses "$TC_internal_IP"/"$TC_internal_netmask" 2>/dev/null; then
    echo -e "${red}Failed to configure network interface!${nc}"
    exit 1
fi

# Re-enable the network connection
nmcli connection down "$connection_name" > /dev/null
sleep 2
nmcli connection up "$connection_name" > /dev/null
kill $connect_pid 2>/dev/null
echo -e "\n${green}Configured $selected_NIC_internal with IP $TC_internal_IP${nc}\n" 


# Install required certification tools
echo
echo "------------------------"
echo "INSTALLING CERT TOOLS..."
echo "------------------------"
echo
sudo apt update && sudo apt upgrade -y
# For VM only
# sudo apt install open-vm-tools -y
! grep -q "checkbox-dev/stable" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null && sudo add-apt-repository ppa:checkbox-dev/stable -y
for lib in maas-cert-server vim openssh-server ifstat checkbox-ng; do
    if ! dpkg -l | grep "$lib" > /dev/null; then
        sudo apt update && sudo apt install $lib -y || { echo -e "${red}Error installing $lib${nc}"; exit 1; }
    fi
done
echo -e "\n${green}Done!${nc}\n" 


# Configure MaaS setting file
echo
echo "-----------------------------"
echo "UPDATEING MAAS CONFIG FILE..."
echo "-----------------------------"
echo

# Add internal IP to iperf.conf 
echo $TC_internal_IP > /etc/maas-cert-server/iperf.conf

# Set network interface in MaaS config file 
sed -i "s#INTERNAL_NET=.*#INTERNAL_NET=$selected_NIC_internal#" /etc/maas-cert-server/config
sed -i "s#EXTERNAL_NET=.*#EXTERNAL_NET=$selected_NIC_external#" /etc/maas-cert-server/config
echo -e "\n${green}Done!${nc}\n" 


# Run MaaS setup tool
sudo maniacs-setup
	

# Launch firefox and navigate to the internal IP
echo -e "\nOpenning firefox...\n"
sudo -H -u $USERNAME firefox $TC_internal_IP > /dev/null 2>&1


exit

