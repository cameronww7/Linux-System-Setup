#!/usr/bin/env zsh

# Note
# ---------------------------------------
# Make sure file has needed perms
# chmod +x terminal_setup.sh

# Install VB Guest additions
# ---------------------------------------
sudo apt update
sudo apt install -y --reinstall virtualbox-guest-x11


# Update the System
# ---------------------------------------
sudo apt clean 
sudo apt upgrade -y 
sudo apt dist-upgrade -y
sudo apt autoremove

# Update the System
# ---------------------------------------
sudo apt install python3
sudo apt install python3-pip

sudo apt install build-essential

sudo apt-get install manpages-dev

# Install Go - https://golang.org/doc/install

sudo wget https://golang.org/dl/go1.16.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.16.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Terminal Tools
# ---------------------------------------


# Tool Install
# ---------------------------------------
sudo apt install gedit
