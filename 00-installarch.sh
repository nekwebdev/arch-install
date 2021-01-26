#!/bin/bash
# Use the command below to run this script.
# $ bash <(curl -sL https://bit.ly/arcsible)

tput setaf 2
echo
echo
echo "###############################################################################"
echo "##################  Installing Vanilla Archlinux from the iso "
echo "###############################################################################"
echo
tput sgr0
echo
echo

mount -o remount,size=4G /run/archiso/cowspace

echo
read -p "Is this a laptop? [y/n] " -n 1 laptop
echo
echo "System drives:"
lsblk
echo
read -p "Installation drive device? sda, nvme0n1p, etc: " diskDevice
echo
echo "Automatic partitioning will create a 300MB boot partition and a swap of your chosen file."
echo "The rest of the disk will be used for the system."
read -p "Do you want to auto configure partitions? [y/n] " -n 1 autoPartition
echo
echo

if [[ $autoPartition =~ ^[Yy]$ ]]
then
  bootPart=1
  swapPart=2
  rootPart=3
  formatBoot="y"
  dualBoot="n"
  windowsPart=0
else
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
  read -p "Boot partition number? " bootPart
  echo
  read -p "Swap partition number? " swapPart
  echo
  read -p "Root partition number? " rootPart
  echo
  read -p "Dual booting windows? [y/n] " -n 1 dualBoot
  echo
  echo
  if [[ $dualBoot =~ ^[Yy]$ ]]
  then
    formatBoot="n"
    read -p "Windows partition number? " windowsPart
    echo
  else
    windowsPart=0
    read -p "Format boot partition? [y/n] " -n 1 formatBoot
    echo
    echo
  fi
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

tput setaf 3
echo "###############################################################################"
echo "##################  Configuring ansible "
echo "###############################################################################"
echo
tput sgr0

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
