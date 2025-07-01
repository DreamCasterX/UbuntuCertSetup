#!/usr/bin/env bash


# CREATOR: Mike Lu (klu7@lenovo.com)
# CHANGE DATE: 6/2/2025
__version__="1.0"


# Ubuntu Hardware Certification Test Environment Setup Script for GPGPU


# Fixed settings
TIME_ZONE='Asia/Taipei'
LXD_GPU_THRESHOLD=35
ppa_build='edge'  # stable or edge
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
CURRENT_TIME_ZONE=$(timedatectl status | grep "Time zone" | awk '{print $3}')
if [ "$CURRENT_TIME_ZONE" != "$TIME_ZONE" ]; then
    sudo timedatectl set-timezone $TIME_ZONE
    sudo ln -sf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime
    sudo timedatectl set-ntp 0 && sleep 1 && timedatectl set-ntp 1
fi


echo "╭─────────────────────────────────────────────────╮"
echo "│   Ubuntu Certification Test Environment Setup   │"
echo "│                      GPGPU                      │"
echo "╰─────────────────────────────────────────────────╯"
# Blacklist NVIDIA open-source GPU driver
echo
echo "----------------------------------"
echo "Block NVIDIA open source driver..."
echo "----------------------------------"
echo
if [[ $(lsmod | grep nouveau) ]] && [[ ! $(grep -w 'blacklist nouveau' /etc/modprobe.d/blacklist.conf) ]]; then
    sudo bash -c "echo 'blacklist nouveau' >> /etc/modprobe.d/blacklist.conf"
    sudo update-initramfs -u
    [[ $? == 0 ]] && sudo systemctl reboot || { echo -e "${red}Failed to blacklist NV driver${nc}"; exit 1; }
fi
echo -e "\n${green}Done!${nc}\n" 


# Update system
[[ ! -f ./upgrade_done ]] && sudo apt update && sudo apt upgrade && touch ./upgrade_done


# Update PCI ID
sudo update-pciids


echo
echo "-----------------------------------"
echo "Installing GPU driver for server..."
echo "-----------------------------------"
echo
if ! dpkg -l | grep -q "ubuntu-drivers-common"; then
    for lib in libc-dev linux-headers-$(uname -r) ubuntu-drivers-common; do
        if ! dpkg -l | grep -q "$lib"; then
            sudo apt install $lib -y || { echo -e "${red}Error installing $lib${nc}"; exit 1; }
        fi
    done
fi

if ! lsmod | grep -q nvidia; then
    # sudo ubuntu-drivers list --gpgpu  # 顯示可用版本
    # sudo ubuntu-drivers install --gpgpu nvidia:570-server  # 安裝指定版本
    sudo ubuntu-drivers install --gpgpu
    nv_ver=`sudo dpkg -l | grep nvidia | head -1 | awk '{print $3}' | cut -d '.' -f1`
    sudo apt install nvidia-utils-$nv_ver-server -y   # 安裝nvidia-smi tool
    [[ $? == 0 ]] && systemctl reboot || { echo -e "${red}Error installing NVIDIA GPU{nc}"; exit 1; }
fi

nvidia-smi
modinfo nvidia |grep -i ^version   # cat /proc/driver/nvidia/version
[[ $? == 0 ]] && echo -e "\n${green}Done!${nc}\n" || { echo -e "${red}Error loading NVIDIA GPU driver{nc}"; exit 1; }


# Download .RUN driver
# https://www.nvidia.com/en-us/drivers/details/242548/

# 移除NV driver
# sudo apt purge nvidia-* libnvidia-* -y
# sudo apt purge *nvidia* -y
# sudo apt autoremove --purge -y
# sudo apt autoclean


# 安裝HWE
# sudo apt install linux-generic-hwe-22.04


# Install certification tools
# 移除 : sudo add-apt-repository --remove ppa:checkbox-dev/"$ppa_build" -y
echo
echo "----------------------"
echo "Installing Checkbox..."
echo "----------------------"
echo
if ! find /etc/apt/sources.list.d/ -maxdepth 1 -type f -name "checkbox-dev-*" | grep -q .; then
    sudo add-apt-repository ppa:checkbox-dev/"$ppa_build" -y
    sudo apt update
fi


for lib in vim openssh-server checkbox-ng canonical-certification-server; do
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
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/x86_64-linux-gnu
echo -e "\n${green}Done!${nc}\n" 


echo
echo "------------------------------------------------"
echo "Check installed snap packages and set LXD env..."
echo "------------------------------------------------"
echo
for pkg in lxd gpu-burn cuda-samples rocm-validation-suite; do
    if ! snap list | grep "$pkg" > /dev/null; then
        sudo snap install "$pkg" || { echo -e "${red}$pkg not installed, please check${nc}"; exit 1 ; }
    fi
done
if ! printenv | grep LXD_GPU_THRESHOLD; then
    sudo snap set lxd environment.LXD_GPU_THRESHOLD=$LXD_GPU_THRESHOLD
    sudo snap restart lxd
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
lxd init --auto

read -p "Start running GPGPU test (y/n)? " ANSWER
while [[ "$ANSWER" != [YyNn] ]]; do 
        read -p "Start running GPGPU test (y/n)? " ANSWER 
done
[[ "$ANSWER" == [Nn] ]] && exit 1

test-gpgpu

exit

