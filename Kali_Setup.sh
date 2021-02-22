# Note
# ---------------------------------------
# Make sure file has needed perms
# chmod +x Kali_Setup.sh

echo "\n Update + Install Basics"

# Install VB Guest additions
# ---------------------------------------
sudo apt-get update
sudo apt-get install -y --reinstall virtualbox-guest-x11

# Update the System
# ---------------------------------------
sudo apt-get clean -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y

# Add search cache
sudo apt-get-cache search kali-

# Install PipMyKali - https://github.com/Dewalt-arch/pimpmykali
# ---------------------------------------
echo "\n Installing - PimyMyKali"
sudo git clone https://github.com/Dewalt-arch/pimpmykali /opt/pimpmykali/
sudo chmod +x /opt/pimpmykali/pimpmykali.sh
cd /opt/pimpmykali/
sudo ./pimpmykali.sh

# Install Dev Tools
# ---------------------------------------
# Install Git
echo "\n Installing - Git"
sudo apt-get install -y git 

# Install Perl
echo "\n Installing - perl"
sudo apt-get install -y perl  

# Install Python
echo "\n Installing - python3 & python"
sudo apt-get install -y python3 
sudo apt-get install -y python

echo "\n Installing - python3-pip& python-pip"
sudo apt-get install -y python3-pip 
sudo apt-get install -y python-pip 

sudo python -m pip install --upgrade pip 

# Install Basic Tools
echo "\n Installing - build-essential "
sudo apt-get install -y build-essential 
sudo apt-get install manpages-dev 

# Install Go - https://golang.org/doc/install
echo "\n Installing - Go"
sudo wget -P /opt/ https://golang.org/dl/go1.16.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf /opt/go1.16.linux-amd64.tar.gz
sudo export PATH=$PATH:/usr/local/go/bin

# Install Atom
echo "\n Installing - Atom"
sudo apt-get install -y  software-properties-common apt-transport-https wget
sudo apt-get  install wget gpg
sudo wget -P /opt/ https://atom.io/download/deb
sudo apt-get install -y /opt/atom-amd64.deb

# Install VSCode
echo "\n Installing - VSCode"
sudo wget -q https://packages.microsoft.com/keys/microsoft.asc -O-
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
sudo apt-get install -y code 


# Tool Install
# ---------------------------------------
sudo apt-get install -y gedit
sudo apt-get install -y gobuster
sudo apt-get install -y sslscan
sudo apt-get install -y nikto
sudo apt-get install -y joomscan
sudo apt-get install -y wpscan
sudo apt-get install -y smbmap
sudo apt-get install -y enum4linux
sudo apt-get install -y dnsrecon
sudo apt-get install -y odat
sudo apt-get install -y seclists
sudo apt-get install -y ffuf
sudo apt-get install -y seclists
sudo apt-get install -y curl 
sudo apt-get install -y nbtscan 
sudo apt-get install -y nmap 
sudo apt-get install -y onesixtyone 
sudo apt-get install -y oscanner 
sudo apt-get install -y smbclient 
sudo apt-get install -y snmp 
sudo apt-get install -y sslscan 
sudo apt-get install -y sipvicious 
sudo apt-get install -y tnscmd10g 
sudo apt-get install -y whatweb 
sudo apt-get install -y khtmltopdf 
sudo apt-get install -y smtp-user-enum 

# Install droopescan - https://github.com/droope/droopescan
sudo pip install droopescan 

# Insatll AutoRecon - https://github.com/Tib3rius/AutoRecon#installation
echo "\n Installing - AutoRecon"
sudo python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git 

# install nmapAutomator - https://github.com/21y4d/nmapAutomator
echo "\n Installing - nmapAutomator"
cd /opt/
sudo git clone https://github.com/21y4d/nmapAutomator.git /opt/nmapAutomator/
sudo ln -s /opt/nmapAutomator/nmapAutomator.sh /usr/local/bin/

# Install Chrome
echo "\n Installing - Chrome"
sudo wget -P /opt/ https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb 
sudo apt-get install -y /opt/google-chrome-stable_current_amd64.deb 

# Install Chromium - Doesnt seem to work...
#echo "\n Installing - chromium-browser "
#echo "\n Installing - chromium-browser "
#sudo apt-get install -y chromium-browser 


# Install Terminal Tools + Customization
# ---------------------------------------
echo "\n Installing - Terminal Tools + Customization"
sudo git clone https://github.com/cameronww7/Terminal-Customization /opt/Terminal-Customization/


# Reboot Prompt
# ---------------------------------------
echo "\n Finished - REBOOT"
