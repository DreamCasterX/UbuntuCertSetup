#!/usr/bin/env bash


# CREATOR: Mike Lu (klu7@lenovo.com)
# CHANGE DATE: 3/3/2025
__version__="1.0"


# Ubuntu Hardware Certification Test Environment Setup Script
# [Note] This script is applicable to physical machine only. 


# User-defined settings
TC_username='master'
log_dir="/home/$TC_username/Desktop/Ubuntu_log"
NFS_dir='/media/Mike/Ubuntu'
secure_id=''


# Fixed settings
TIME_ZONE='Asia/Taipei'
TC_internal_IP='192.168.20.1'
TC_internal_netmask='24'
TC_external_netmask='22'
TC_external_gateway='192.168.4.7'
TC_external_dns='10.240.0.10'
NFS_IP='10.241.180.56'
NFS_port='6000'
SUT_username='ubuntu'
SUT_passwd='ubuntu'
Config_file_2204='/etc/xdg/canonical-certification.conf'
Config_file_2404='/etc/xdg/canonical-certification.conf.dpkg.new'
red='\e[41m'
green='\e[32m'
yellow='\e[93m'
nc='\e[0m'


# Ensure the user is running the script as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${yellow}Please run as root to start the installation.${nc}"
    exit 1
fi


# Ensure Internet is connected
CheckInternet() {
nslookup "google.com" > /dev/null
if [ $? != 0 ]; then 
    echo -e "${red}No Internet connection! Please check your network${nc}" && sleep 5 && exit 1
fi
}
CheckInternet
    

# Check the latest update of this script
UpdateScript() {
release_url=https://api.github.com/repos/DreamCasterX/UbuntuCertSetup/releases/latest
new_version=$(wget -qO- "${release_url}" | grep '"tag_name":' | awk -F\" '{print $4}')
release_note=$(wget -qO- "${release_url}" | grep '"body":' | awk -F\" '{print $4}')
tarball_url="https://github.com/DreamCasterX/UbuntuCertSetup/archive/refs/tags/${new_version}.tar.gz"
if [[ $__version__ != $new_version ]]; then
    echo -e "⭐️ New version found!\n\nVersion: $new_version\nRelease note:\n$release_note"
    sleep 2
    echo -e "\nDownloading update..."
    pushd "$PWD" > /dev/null 2>&1
    wget --quiet --no-check-certificate --tries=3 --waitretry=2 --output-document=".UbuntuCertSetup.tar.gz" "${tarball_url}"
    if [[ -e ".UbuntuCertSetup.tar.gz" ]]; then
        tar -xf .UbuntuCertSetup.tar.gz -C "$PWD" --strip-components 1 > /dev/null 2>&1
        rm -f .UbuntuCertSetup.tar.gz
        rm -f README.md
        popd > /dev/null 2>&1
        sleep 3
        sudo chmod 755 UbuntuCertSetup.sh
        echo -e "Successfully updated! Please run UbuntuCertSetup.sh again.\n\n" ; exit 1
    else
        echo -e "\n❌ Error occurred while downloading the update" ; exit 1
    fi 
fi
}
# UpdateScript


# Get configuration type from user
echo "╭─────────────────────────────────────────────────────╮"
echo "│    Ubuntu Certification Test Environment Setup      │"
echo "╰─────────────────────────────────────────────────────╯"
echo "Select an option to configure"
read -p "(t)TC  (s)SUT:  (c)Copy log: " OPTION
while [[ "$OPTION" != [SsTtCc] ]]; do 
    read -p "(t)TC  (s)SUT   (c)Copy log: " OPTION
done   


if [[ "$OPTION" == [Tt] ]]; then
    # Customize keyboard shortcut
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
    CUR_USER=$(grep "^[^#\[]" "$CONFIG_FILE" | grep "AutomaticLogin=" | cut -d '=' -f 2)

    if [[ -z "$AUTOLOGIN_ENABLE" ]]; then
        # AutomaticLoginEnable is not set, so enable it and set the new user
        sed -i "s/\[daemon\]/[daemon]\nAutomaticLoginEnable=True\nAutomaticLogin=${NEW_USER}/" "$CONFIG_FILE"
        echo -e "Set user [$NEW_USER] to auto login and enabled AutomaticLoginEnable.\n"
    elif [[ "$AUTOLOGIN_ENABLE" == "True" ]]; then
        # AutomaticLoginEnable is already enabled, so update the user
        if [[ -n "$CUR_USER" && "$CUR_USER" != "$NEW_USER" ]]; then
            sed -i "s/AutomaticLogin=${CUR_USER}/AutomaticLogin=${NEW_USER}/" "$CONFIG_FILE"
            echo -e "Changed auto login user from [$CUR_USER] to [$NEW_USER].\n"
        fi
    else
        # AutomaticLoginEnable is set to False, so enable it and set the new user
        sed -i "s/AutomaticLoginEnable=${AUTOLOGIN_ENABLE}/AutomaticLoginEnable=True/" "$CONFIG_FILE"
        if [[ -n "$CUR_USER" ]]; then
            sed -i "s/AutomaticLogin=${CUR_USER}/AutomaticLogin=${NEW_USER}/" "$CONFIG_FILE"
        else
            sed -i "s/\[daemon\]/[daemon]\nAutomaticLogin=${NEW_USER}/" "$CONFIG_FILE"
        fi
        echo -e "Set user [$NEW_USER] to auto login and enabled AutomaticLoginEnable.\n"
    fi


    # Set TC hostname
    ! hostname | grep 'TC' > /dev/null && hostnamectl set-hostname 'TC' 

    # Configure TC network
    echo
    echo "----------------------------"
    echo "CONFIGURING TC NETWORK IP..."
    echo "----------------------------"
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
    echo -e "Selected device (External): ${yellow}$selected_NIC_external${nc}\n"


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
    echo -e "Selected device (Internal): ${yellow}$selected_NIC_internal${nc}\n"


    # Enable the network connection for selected interface (Internal only)
    nmcli device connect $selected_NIC_internal > /dev/null 2>&1 &
    connect_pid=$!
    sleep 2

    # Get connection name from the selected interfaces
    connection_name_external=$(nmcli device show $selected_NIC_external | grep "GENERAL.CONNECTION" | awk '{$1=""; sub(/^ */, ""); gsub(/[[:space:]]*$/, ""); print}') 
    connection_name_internal=$(nmcli device show $selected_NIC_internal | grep "GENERAL.CONNECTION" | awk '{$1=""; sub(/^ */, ""); gsub(/[[:space:]]*$/, ""); print}') 
    
    # Set external IP/etmask/gateway/DNS 
    TC_external_IP=$(ip addr show "$selected_NIC_external" | grep -w 'inet' | awk '{print $2}' | cut -d/ -f1)
    if ! nmcli connection modify "$connection_name_external" ipv4.method manual ipv4.addresses "$TC_external_IP"/"$TC_external_netmask" ipv4.gateway "$TC_external_gateway" ipv4.dns "$TC_external_dns" 2>/dev/null; then
        echo -e "${red}Failed to configure network interface!${nc}"
        exit 1
    fi
    
    # Set internal IP and netmask 
    if ! nmcli connection modify "$connection_name_internal" ipv4.method manual ipv4.addresses "$TC_internal_IP"/"$TC_internal_netmask" 2>/dev/null; then
        echo -e "${red}Failed to configure network interface!${nc}"
        exit 1
    fi

    # Re-enable the network connections
    nmcli connection down "$connection_name_external" > /dev/null
    nmcli connection down "$connection_name_internal" > /dev/null
    sleep 2
    nmcli connection up "$connection_name_external" > /dev/null
    nmcli connection up "$connection_name_internal" > /dev/null
    kill $connect_pid 2>/dev/null
    echo -e "\n${green}Configured $selected_NIC_external with IP $TC_external_IP${nc}\n" 
    echo -e "${green}Configured $selected_NIC_internal with IP $TC_internal_IP${nc}\n" 


    # Install required certification tools
    echo
    echo "------------------------"
    echo "INSTALLING CERT TOOLS..."
    echo "------------------------"
    echo
    sudo apt update && sudo apt upgrade -y
    # sudo apt install open-vm-tools -y (For VM only)
    ! grep -q "checkbox-dev/stable" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null && sudo add-apt-repository ppa:checkbox-dev/stable -y
    for lib in maas-cert-server vim openssh-server ifstat checkbox-ng sshpass; do
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
  
    echo
    echo "----------------------------------------"
    echo "✅ UBUNTU CERTIFICATION SETUP COMPLETED"
    echo "----------------------------------------"
    echo
    
    # Launch firefox and navigate to the internal IP
    echo -e "\nOpenning firefox for X11\n" && sudo -H -u $USERNAME firefox $TC_internal_IP > /dev/null 2>&1
    
       
elif [[ "$OPTION" == [Ss] ]]; then
    echo
    read -p "Enter SUT's IP: " SUT_IP
    ping -c 3 "$SUT_IP" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        if [ ! -f ~/.ssh/id_rsa ]; then
            ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
        fi
    else
        echo -e "${red}Ping to $SUT_IP failed. Please check the IP address and network connection.${nc}"
        exit 1
    fi
    # sshpass -p "$SUT_passwd" ssh-copy-id -o StrictHostKeyChecking=no "$SUT_username@$SUT_IP" > /dev/null
   
    # Display SUT information
    SUT_OS_VER=$(sshpass -p "$SUT_passwd" ssh -o StrictHostKeyChecking=no "$SUT_username@$SUT_IP" "cat /etc/os-release | grep ^VERSION_ID= | awk -F= '{print \$2}' | cut -d '\"' -f2")
    SUT_kernel=$(sshpass -p "$SUT_passwd" ssh -o StrictHostKeyChecking=no "$SUT_username@$SUT_IP" "uname -r") #要先ssh到SUT
    sb_state=$(sshpass -p "$SUT_passwd" ssh -o StrictHostKeyChecking=no "$SUT_username@$SUT_IP" 'mokutil --sb-state | cut -d " " -f2')
    echo
    echo "------------------------"
    echo "CHECK SUT SYSTEM INFO..."
    echo "------------------------"
    echo
    echo -e "OS: ${yellow}$SUT_OS_VER${nc}"
    echo -e "Kernel: ${yellow}$SUT_kernel${nc}"
    echo -e "Secure boot state: ${yellow}$sb_state${nc}\n"
    read -p "Is it okay to continue (y/n)? " ANSWER 
    while [[ "$ANSWER" != [YyNn] ]]; do 
        read -p "Is it okay to continue (y/n)? " ANSWER 
    done
    [[ "$ANSWER" == [Nn] ]] && exit 1
    

    # Set local time zone and reset NTP
    echo
    echo "----------------"
    echo "SET TIME ZONE..."
    echo "----------------"
    echo
    sshpass -p "$SUT_passwd" ssh -o StrictHostKeyChecking=no "$SUT_username@$SUT_IP" "
    echo '$SUT_passwd' | sudo -S timedatectl set-timezone $TIME_ZONE
    echo '$SUT_passwd' | sudo -S ln -sf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime
    echo '$SUT_passwd' | sudo -S timedatectl set-ntp 0 && sleep 1 && echo '$SUT_passwd' | sudo -S timedatectl set-ntp 1
    "
    [[ $? = 0 ]] && echo -e "\n${green}Done!${nc}\n" || { echo -e "${red}Failed to set time zone on SUT${nc}"; exit 1; }
    
       
    # Set TEST_TARGET_IPERF env variable
    # Need to open a new Termianl to view the changes
    echo
    echo "----------------------------"
    echo "SET TEST_TARGET_IPERF ENV..."
    echo "----------------------------"
    echo
    sshpass -p "$SUT_passwd" ssh -o StrictHostKeyChecking=no "$SUT_username@$SUT_IP" "
    if ! grep -q 'export TEST_TARGET_IPERF=' ~/.bashrc; then
        echo \"export TEST_TARGET_IPERF=\\\"$TC_internal_IP\\\"\" >> ~/.bashrc
        source ~/.bashrc
    fi
    "
    [[ $? = 0 ]] && echo -e "\n${green}Done!${nc}\n" || { echo -e "${red}Failed to set ENV on SUT${nc}"; exit 1; }
    
    
    # Configure iperf3 and set MTU value on both TC & SUT
    echo
    echo "----------------------------------"
    echo "CONFIG IPERF3 AND SET MTU VALUE..."
    echo "----------------------------------"
    echo
    echo -e "Select a network speed for iperf3 testing"
    read -p "(1)1G-10G   (2)25G   (3)100G: " SPEED
    while [[ "$SPEED" != [123] ]]; do 
        read -p "(1)1G-10G   (2)25G   (3)100G   : " SPEED
    done
    pkill iperf3
    if [[ $SPEED == '1' ]]; then
        # Start iperf3 for 1G-10G speed
        start-iperf3 -a $TC_internal_IP -n 2
        
    elif [[ $SPEED == '2' ]]; then
        # Start iperf3 for 25G speed
        start-iperf3 -a $TC_internal_IP -n 6
        # Modify TC network MTU in setting (For speed > 25G only)
        connection_name_internal=$(nmcli device show | grep -B10 "$TC_internal_IP" | awk '{$1=""; sub(/^ */, ""); gsub(/[[:space:]]*$/, ""); print}')
        sudo nmcli connection modify "$connection_name_internal" 802-3-ethernet.mtu 9000  # default: automatic (0)
        sudo nmcli connection up "$connection_name_internal" > /dev/null  
        # Modify SUT network MTU in YAML file (For speed > 25G only)   
        sshpass -p "$SUT_passwd" ssh -o StrictHostKeyChecking=no "$SUT_username@$SUT_IP" "
        echo '$SUT_passwd' | sudo -S sed -i 's/mtu: 1500/mtu: 9000\n    optional: true/' /etc/netplan/50-cloud-init.yaml
        echo '$SUT_passwd' | sudo -S netplan apply
        "
                
    elif [[ $SPEED == '3' ]]; then
        # Start iperf3 for 100G speed
        start-iperf3 -a $TC_internal_IP -n 20
        # Modify TC network MTU in setting (For speed > 25G only)
        connection_name_internal=$(nmcli device show | grep -B10 "$TC_internal_IP" | awk '{$1=""; sub(/^ */, ""); gsub(/[[:space:]]*$/, ""); print}')
        sudo nmcli connection modify "$connection_name_internal" 802-3-ethernet.mtu 9000  # default: automatic (0)
        sudo nmcli connection up "$connection_name_internal" > /dev/null 
        # Modify SUT network MTU in YAML file (For speed > 25G only)   
        sshpass -p "$SUT_passwd" ssh -o StrictHostKeyChecking=no "$SUT_username@$SUT_IP" "
        echo '$SUT_passwd' | sudo -S sed -i 's/mtu: 1500/mtu: 9000\n    optional: true/' /etc/netplan/50-cloud-init.yaml
        echo '$SUT_passwd' | sudo -S netplan apply
        "
    fi
    [[ $? = 0 ]] && echo -e "\n${green}Done!${nc}\n" || { echo -e "${red}Failed to modify MTU on TC or SUT${nc}"; exit 1; }


    # Modify checkbox config file  
    echo
    echo "------------------------------"
    echo "UPDATE CHECKBOX CONFIG FILE..."
    echo "------------------------------"
    echo
    if [[ $SUT_OS_VER == '22.04' ]]; then
        checkbox_setting=$Config_file_2204
    else
        checkbox_setting=$Config_file_2404
    fi
    
    sshpass -p "$SUT_passwd" ssh -o StrictHostKeyChecking=no "$SUT_username@$SUT_IP" "
    [common]
    
    sed -i 's/# [transport:c3]/[transport:c3]/' $checkbox_setting
    sed -i 's/# secure_id = /secure_id = $secure_id/' $checkbox_setting
    
    # KVM_IMAGE = http://cloud-images.ubuntu.com/daily/server/daily/server/{release}

    ! grep -q KVM_IMAGE = http://192.168.20.1/cloud/jammy-server-cloudimg-amd64.img              # 取消注释并更改jammy-server-cloudimg-amd64.img文件的地址
    ! grep -q UVT_IMAGE_OR_SOURCE = http://192.168.20.1/cloud/jammy-server-cloudimg-amd64.img    # 添加UVT参数
    
    ! grep -q LXD_ROOTFS = http://$TC_internal_IP/cloud/jammy-server-cloudimg-amd64.squashfs >> /etc/xdg/canonical-certification.conf  
    ! grep -q LLXD_TEMPLATE = http://$TC_internal_IP/cloud/jammy-server-cloudimg-amd64-lxd.tar.xz >> /etc/xdg/canonical-certification.conf  
    ! grep -q TEST_TARGET_IPERF = $TC_internal_IP  >> /etc/xdg/canonical-certification.conf  
    "
    
    
    # 檢查環境配置 
    #canonical-certification-precheck 
   
 
    #刪除文件 
    #路徑: /var/crash 

    #sudo rm -rf iperf3.0 crash 


    # Run checkbox
    # certify-ubuntu-server(24.04用這個指令) 
    # certify-22.04(22.04用這個指令) 

elif [[ "$OPTION" == [Cc] ]]; then
    echo
    read -p "Enter SUT's IP: " SUT_IP
    ping -c 3 "$SUT_IP" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        if [ ! -f ~/.ssh/id_rsa ]; then
            ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
        fi
    else
        echo -e "${red}Ping to $SUT_IP failed. Please check the IP address and network connection.${nc}"
        exit 1
    fi
    # sshpass -p "$SUT_passwd" ssh-copy-id -o StrictHostKeyChecking=no "$SUT_username@$SUT_IP" > /dev/null
    
    
    # Copy test logs from SUT to TC
    echo
    echo "--------------------------"
    echo "COPY TEST LOGS FROM SUT..."
    echo "--------------------------"
    echo
    mkdir -p $log_dir
    sshpass -p "$SUT_passwd" scp -o StrictHostKeyChecking=no "$SUT_username@$SUT_IP:/home/${SUT_username}/.local/share/*tar.xz" $log_dir
    [[ $? = 0 ]] && ls -ltrh $log_dir && echo -e "\n${green}Done!${nc}\n" || { echo -e "${red}Failed to copy test logs from SUT${nc}"; exit 1; }
    # chmod -R +x $log_dir
    
   
    # Upload test logs from TC to NFS
    echo
    echo "--------------------------"
    echo "UPLOAD TEST LOGS TO NFS..."
    echo "--------------------------"
    echo 
    ping -c 3 "$NFS_IP" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        if [ ! -f ~/.ssh/id_rsa ]; then
            ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
        fi
    else
        echo -e "${red}Ping to $NFS_IP failed. Please check the IP address and network connection.${nc}"
        exit 1
    fi
    scp -r -P $NFS_port $log_dir root@$NFS_IP:$NFS_dir
    # sshpass -p "$NFS_passwd" scp -o StrictHostKeyChecking=no -r -P $NFS_port $log_dir root@$NFS_IP:$NFS_dir
    [[ $? = 0 ]] && echo -e "\n${green}Done!${nc}\n" || { echo -e "${red}Failed to upload test logs to NFS${nc}"; exit 1; }

fi

exit

