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
sudo apt clean -y
sudo apt upgrade -y 
sudo apt dist-upgrade -y
sudo apt autoremove -y

sudo apt install -y ocl-icd-libopencl1 nvidia-driver nvidia-cuda-toolkit -y

sudo apt-cache search kali- -y

# Install Pip my Kali
# ---------------------------------------
sudo git clone https://github.com/Dewalt-arch/pimpmykali /opt/

# Install Dev Tools
# ---------------------------------------
sudo apt install git -y

# Install Perl
sudo apt install perl -y 

# Install Python
sudo apt install python3 -y
sudo apt install python3-pip -y

sudo apt install python -y 
sudo apt install python-pip -y

# Install Basic Tools
sudo apt install build-essential -y
sudo apt-get install manpages-dev -y

# Install Go - https://golang.org/doc/install
sudo wget https://golang.org/dl/go1.16.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.16.linux-amd64.tar.gz
sudo export PATH=$PATH:/usr/local/go/bin


# Tool Install
# ---------------------------------------
sudo apt install gedit -y
sudo apt install gobuster -y
sudo apt install sslscan -y
sudo apt install nikto -y
sudo apt install joomscan -y
sudo apt install wpscan -y
sudo apt install smbmap -y
sudo apt install enum4linux -y
sudo apt install dnsrecon -y
sudo apt install odat -y
sudo apt install seclists -y
sudo apt install ffuf -y
sudo apt install seclists -y
sudo apt install curl -y
sudo apt install nbtscan -y
sudo apt install nmap -y
sudo apt install onesixtyone -y
sudo apt install oscanner -y
sudo apt install smbclient -y
sudo apt install snmp -y
sudo apt install sslscan -y
sudo apt install sipvicious -y
sudo apt install tnscmd10g -y
sudo apt install whatweb -y
sudo apt install khtmltopdf -y
sudo apt-get install smtp-user-enum -y

# Install droopescan - https://github.com/droope/droopescan
sudo pip install droopescan -y

# Insatll AutoRecon - https://github.com/Tib3rius/AutoRecon#installation
sudo python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git -y

# install nmapAutomator - https://github.com/21y4d/nmapAutomator
sudo git clone https://github.com/21y4d/nmapAutomator.git /opt/
sudo ln -s /opt/nmapAutomator/nmapAutomator.sh /usr/local/bin/

# Install Chrome
sudo wget /opt/ https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb 
sudo apt install /opt/google-chrome-stable_current_amd64.deb -y

# Install Chromium - Doesnt seem to work...
sudo apt install chromium-browser -y

# Install VS Code
sudo apt install software-properties-common apt-transport-https wget
sudo wget -q https://packages.microsoft.com/keys/microsoft.asc -O-
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
sudo apt install code -y


# Install Terminal Tools + Customization
# ---------------------------------------
sudo wget https://github.com/cameronww7/Terminal-Customization /opt/
sudo chmod +x /opt/Terminal-Customization/terminal_setup.sh
sudo sh /opt/Terminal-Customization/terminal_setup.sh

