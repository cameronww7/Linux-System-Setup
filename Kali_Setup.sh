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
sudo apt upgrade  
sudo apt dist-upgrade 
sudo apt autoremove 

# Install Video Drivers
sudo apt install -y ocl-icd-libopencl1 nvidia-driver nvidia-cuda-toolkit

# Add search cache
sudo apt-cache search kali- 

# Install PipMyKali - https://github.com/Dewalt-arch/pimpmykali
# ---------------------------------------

sudo git clone https://github.com/Dewalt-arch/pimpmykali /opt/
sudo chmod +x /opt/pimpmykali/pimpmykali.sh
cd /opt/pimpmykali/
sudo ./pimpmykali/pimpmykali.sh

# Install Dev Tools
# ---------------------------------------
sudo apt install -y git 

# Install Perl
sudo apt install -y perl  

# Install Python
sudo apt install -y python3 
sudo apt install -y python3-pip 

sudo apt install -y python  
sudo apt install -y python-pip 

# Install Basic Tools
sudo apt install -y build-essential 
sudo apt-get install manpages-dev 

# Install Go - https://golang.org/doc/install
sudo wget https://golang.org/dl/go1.16.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.16.linux-amd64.tar.gz
sudo export PATH=$PATH:/usr/local/go/bin

# Install Atom
sudo apt install -y  software-properties-common apt-transport-https wget
sudo apt  install wget gpg
sudo wget /opt/ https://atom.io/download/deb
sudo apt install -y /opt/atom-amd64.deb

# Install VS Code
sudo wget -q https://packages.microsoft.com/keys/microsoft.asc -O-
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
sudo apt install -y code 


# Tool Install
# ---------------------------------------
sudo apt install -y gedit 
sudo apt install -y gobuster 
sudo apt install -y sslscan 
sudo apt install -y nikto 
sudo apt install -y joomscan 
sudo apt install -y wpscan 
sudo apt install -y smbmap 
sudo apt install -y enum4linux 
sudo apt install -y dnsrecon 
sudo apt install -y odat 
sudo apt install -y seclists 
sudo apt install -y ffuf 
sudo apt install -y seclists 
sudo apt install -y curl 
sudo apt install -y nbtscan 
sudo apt install -y nmap 
sudo apt install -y onesixtyone 
sudo apt install -y oscanner 
sudo apt install -y smbclient 
sudo apt install -y snmp 
sudo apt install -y sslscan 
sudo apt install -y sipvicious 
sudo apt install -y tnscmd10g 
sudo apt install -y whatweb 
sudo apt install -y khtmltopdf 
sudo apt install -y smtp-user-enum 

# Install droopescan - https://github.com/droope/droopescan
sudo pip install droopescan 

# Insatll AutoRecon - https://github.com/Tib3rius/AutoRecon#installation
sudo python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git 

# install nmapAutomator - https://github.com/21y4d/nmapAutomator
cd /opt/
sudo git clone https://github.com/21y4d/nmapAutomator.git /opt/
sudo ln -s /opt/nmapAutomator/nmapAutomator.sh /usr/local/bin/

# Install Chrome
sudo wget /opt/ https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb 
sudo apt install -y /opt/google-chrome-stable_current_amd64.deb 

# Install Chromium - Doesnt seem to work...
sudo apt install -y chromium-browser 


# Install Terminal Tools + Customization
# ---------------------------------------
sudo wget https://github.com/cameronww7/Terminal-Customization /opt/
sudo chmod +x /opt/Terminal-Customization/terminal_setup.sh
cd /opt/Terminal-Customization/
sudo ./opt/Terminal-Customization/terminal_setup.sh


# Reboot
# ---------------------------------------
reboot