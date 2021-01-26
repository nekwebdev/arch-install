# arch-install

This project is an ansible playbook to install a vanilla arch linux from the live iso.

## Installation

Boot on your arch live iso.
Load your keyboard layout `loadkeys fr-latin1`
Get online.
Use this command to download the `00-installarch.sh` script to setup the dependencies, clone this project and start the install:

`bash <(curl -sL https://bit.ly/nekarch)`

## Configuration

The initial bash script will ask a few configuration option questions. Currently it has support for auto partitioning of a drive: boot EFI of 300M, a swap of a chosen size and the rest for the drive for root. Manual partitionting where you then only assign parition numbers. It also supports windows dual boot and will not format the current EFI partition.

The filesystem will be btrfs and the install will configure everything for snapshots according to the arch and snapper wikis.

Quadruple check the config file at the end of the bash script as thats what the playbook will run of.

## Next steps

At the end it will clone my [arch-config](https://github.com/nekwebdev/arch-config.git) project into root's home to configure a desktop environment after reboot.
