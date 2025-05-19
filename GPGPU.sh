#!/usr/bin/env bash


# CREATOR: Mike Lu (klu7@lenovo.com)
# CHANGE DATE: 5/19/2025
__version__="1.0"


# Ubuntu Hardware Certification Test Environment Setup Script


# Fixed settings
TIME_ZONE='Asia/Taipei'
red='\e[41m'
green='\e[32m'
yellow='\e[93m'
nc='\e[0m'


# Ensure the user is running the script as root
if [[ "$EUID" == 0 ]]; then 
    echo -e "${yellow}Please run as normal user to start the installation.${nc}"
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
    

# Set local time zone and reset NTP
sudo timedatectl set-timezone $TIME_ZONE
sudo ln -sf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime
sudo timedatectl set-ntp 0 && sleep 1 && timedatectl set-ntp 1



echo "╭─────────────────────────────────────────────────╮"
echo "│   Ubuntu Certification Test Environment Setup   │"
echo "│                      GPGPU                      │"
echo "╰─────────────────────────────────────────────────╯"
# Blacklist NVIDIA open-source GPU driver
echo
echo "----------------------------------"
echo "BLOCK NVIDIA OPEN SOURCE DRIVER..."
echo "----------------------------------"
echo
if [[ $(lsmod | grep nouveau) ]] && [[ ! $(grep -w 'blacklist nouveau' /etc/modprobe.d/blacklist.conf) ]]; then
    echo 'blacklist nouveau' >> /etc/modprobe.d/blacklist.conf
    update-initramfs -u
    [[ $? == 0 ]] && systemctl reboot || { echo -e "${red}Failed to blacklist NV driver${nc}"; exit 1; }
fi
echo -e "\n${green}Done!${nc}\n" 


# Update system
sudo apt update && sudo apt upgrade -y


echo
echo "------------------------"
echo "Installing GPU driver..."
echo "------------------------"
echo
if ! dpkg -l | grep -q "ubuntu-drivers-common"; then
    for lib in libc-dev linux-headers-$(uname -r) ubuntu-drivers-common; do
        if ! dpkg -l | grep -q "$lib"; then
            sudo apt install $lib -y || { echo -e "${red}Error installing $lib${nc}"; exit 1; }
        fi
    done
    ubuntu-drivers install
    [[ $? == 0 ]] && systemctl reboot || { echo -e "${red}Error installing ubuntu-drivers{nc}"; exit 1; }
fi
modinfo nvidia |grep -i ^version
nvidia-smi
echo -e "\n${green}Done!${nc}\n" 


# Install certification tools
echo
echo "----------------------"
echo "Installing Checkbox..."
echo "----------------------"
echo
! grep -q "checkbox-dev/stable" /etc/apt/sources.list /etc/apt/sources.list.d/*.list && sudo add-apt-repository ppa:checkbox-dev/stable -y
for lib in vim openssh-server checkbox-ng canonical-certification-server -y; do
    if ! dpkg -l | grep -q "$lib"; then
        sudo apt install $lib -y || { echo -e "${red}Error installing $lib${nc}"; exit 1; }
    fi
done
echo -e "\n${green}Done!${nc}\n" 


# Install gpgpu package
echo
echo "---------------------------"
echo "Installing GPGPU package..."
echo "---------------------------"
echo
# This will install snap packages of cuda-samples, gpu-burn, rocm-validation-suite (for AMD)
if ! dpkg -l | grep -q "checkbox-provider-gpgpu"; then
    sudo apt install checkbox-provider-gpgpu -y || { echo -e "${red}Error installing GPGPU package{nc}"; exit 1; }
fi
echo -e "\n${green}Done!${nc}\n" 



nvlink () {
    # Special settings for NVIDIA GPUs that support NVLink/NVSwitch
    echo
    echo "---------------------"
    echo "Configuring NVLink..."
    echo "---------------------"
    echo
    nv_driver_branch=$(modinfo nvidia |grep -i ^version | awk '{print $2}' | cut -d '.' -f1)


    sudo apt install nvidia-fabricmanager-$nv_driver_branch libnvidia-nscq-$nv_driver_branch datacenter-gpu-manager
    # Start the fabricmanager service
    sudo systemctl start nvidia-fabricmanager.service
    # Start the persistence daemon
    sudo service nvidia-persistenced start
    # Start nv-hostengine
    sudo nv-hostengine
    # Set up a group
    dcgmi group -c GPU_Group
    dcgmi group -l
    # Discover GPUs
    dcgmi discovery -l
    # Add GPUs to group
    dcgmi group -g 2 -a 0,1,2,3
    dcgmi group -g 2 -i
    # Set up health monitoring
    dcgmi health -g 2 -s mpi
    # Run the diag to check
    dcgmi diag -g 2 -r 1
}
#nvlink


# Normal user run
test-gpgpu

exit

