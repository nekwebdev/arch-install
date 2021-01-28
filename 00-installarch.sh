#!/bin/bash
# Use the command below to run this script.
# $ bash <(curl -sL https://bit.ly/archnek)

tput setaf 2
echo
echo
echo "###############################################################################"
echo "##################  Installing Vanilla Archlinux from the iso "
echo "###############################################################################"
tput sgr0

mount -o remount,size=4G /run/archiso/cowspace

echo
read -p "Is this a laptop? [Y/n] " -n 1 laptop
echo
if [[ ! $autoPartition =~ ^[Nn]$ ]]
then
  laptop="y"
fi

echo "System drives:"
lsblk
echo
read -p "Installation drive? [nvme0n1/]: " diskDevice
echo
if [[ $diskDevice == "" ]]
then
  diskDevice="nvme0n1"
fi
echo "Automatic partitioning will create a 300MB boot partition and a swap of your chosen file."
echo "The rest of the disk will be used for the system."
read -p "Do you want to auto configure partitions? [y/N] " -n 1 autoPartition
echo
echo

if [[ $autoPartition =~ ^[Yy]$ ]]
then
  bootPart=1
  swapPart=2
  rootPart=3
  formatBoot="y"
  dualBoot="n"
  windowsPart="0"
else
  autoPartition="n"
  cgdisk /dev/${diskDevice}
  tput setaf 3
  echo "###############################################################################"
  echo "##################  Select partitions "
  echo "###############################################################################"
  echo
  tput sgr0
  echo "System drives:"
  lsblk
  echo
  read -p "Boot partition number? [1/] " bootPart
  echo
  if [[ $bootPart == "" ]]
  then
    bootPart="1"
  fi
  read -p "Swap partition number? [5/] " swapPart
  echo
  if [[ $swapPart == "" ]]
  then
    swapPart="5"
  fi
  read -p "Root partition number? [6/] " rootPart
  echo
  if [[ $rootPart == "" ]]
  then
    rootPart="6"
  fi
  read -p "Dual booting windows? [Y/n] " -n 1 dualBoot
  echo
  if [[ $dualBoot =~ ^[Nn]$ ]]
  then
    windowsPart="0"
    read -p "Format boot partition? [Y/n] " -n 1 formatBoot
    echo
    if [[ ! $formatBoot =~ ^[Nn]$ ]]
    then
      formatBoot="y"
    fi
  else
    dualBoot="y"
    formatBoot="n"
    read -p "Windows partition number? [3/] " windowsPart
    echo
    if [[ $windowsPart == "" ]]
    then
      windowsPart="3"
    fi
  fi
fi
# Add the p for display
if [[ $diskDevice = *nvme* ]]
then
  diskDevice="${diskDevice}p"
fi
tput setaf 2
echo "###############################################################################"
echo "##################  Confirm settings "
echo "###############################################################################"
echo
tput sgr0
echo "System drives:"
lsblk
echo
echo "Are we setting up a laptop? ${laptop}"
echo
echo "Automatic paritioning? ${autoPartition}"
echo
echo "Boot partition: /dev/${diskDevice}${bootPart}"
echo "Swap partition: /dev/${diskDevice}${swapPart}"
echo "Root partition: /dev/${diskDevice}${rootPart}"
echo
echo "Are we dual booting? ${dualBoot}"
if [[ $dualBoot =~ ^[Yy]$ ]]
then
  echo "Windows partition: /dev/${diskDevice}${windowsPart}"
fi
echo "Are we formating boot partition? ${formatBoot}"
echo
read -p "Are these settings correct? [y/N] " -n 1 confirm
echo

if [[ ! $confirm =~ ^[Yy]$ ]]
then
  echo "Gotcha, we can try again later bob..."
  exit 1
fi

if [[ $autoPartition =~ ^[Yy]$ ]]
then
  tput setaf 3
  echo "###############################################################################"
  echo "##################  Automatic partitioning "
  echo "###############################################################################"
  echo
  tput sgr0
  # strip the p again
  if [[ $diskDevice = *nvme* ]]
  then
    diskDevice=${diskDevice%?}
  fi
  read -p "Swap size? 500M, 2G, 4G, etc " swapSize
  sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | gdisk /dev/${diskDevice}
  o # create new empty GUID partition table
  Y # confirm changes
  n # new partition
    # default - first partition
    # default - start at beginning of disk 
  +300M # 300 MB boot partition
  ef00 # efi type
  n # new partition
    # default - second partition
    # default - start immediately after preceding partition
  +${swapSize} # custom size swap partition
  8200 # swap type
  n # new partition
    # default - third partition
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
    # default, linux type
  w # write changes
  Y # confirm changes
EOF
  # Add the p for save in config
  if [[ $diskDevice = *nvme* ]]
  then
    diskDevice="${diskDevice}p"
  fi
fi

echo
lsblk
echo

tput setaf 3
echo "###############################################################################"
echo "##################  Installing ansible "
echo "###############################################################################"
echo
tput sgr0

pacman -Syy --noconfirm vim git ansible
ansible-galaxy collection install community.general

git clone git://github.com/nekwebdev/arch-install

cd arch-install
cat > config.yml << EOF
---
#######################################
# DEFAULTS change to fit

hostname: "zephy"

# localisation data
timezone: "Pacific/Tahiti"
locale: "en_US"
locale_encoding: "UTF-8"
keymap: "fr-latin1"

########################################
# GENERATED check em!

laptop: "${laptop}"
dual_boot: "${dualBoot}"
format_boot: "${formatBoot}"

# partition variables
boot: "${diskDevice}${bootPart}"
swap: "${diskDevice}${swapPart}"
root: "${diskDevice}${rootPart}"
windows: "${diskDevice}${windowsPart}"
EOF
vim config.yml

tput setaf 3
echo "###############################################################################"
echo "##################  Starting ansible "
echo "###############################################################################"
echo
tput sgr0
ansible-playbook -i localhost playbook.yml
echo
echo
tput setaf 2
echo "###############################################################################"
echo "##################  Installation complete "
echo "###############################################################################"
echo
echo "Job done!"
echo "umount -a"
echo "reboot"
tput sgr0
exit 0
