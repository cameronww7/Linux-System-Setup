# Note
# ---------------------------------------
# Make sure file has needed perms
# chmod +x Kali_Setup.sh

echo "\n\n\n Update + Install Basics"

# Install VB Guest additions
# ---------------------------------------
sudo apt-get update
sudo apt-get install -y --reinstall virtualbox-guest-x11

# Update the System
# ---------------------------------------
sudo apt-get clean -y
sudo apt-get full-upgrade -y
sudo apt-get autoremove -y

# Add search cache
sudo apt-get-cache search kali-

# Cloning PipMyKali - https://github.com/Dewalt-arch/pimpmykali
# ---------------------------------------
echo "\n\n\n Cloning - PimyMyKali \n"
sudo git clone https://github.com/Dewalt-arch/pimpmykali /opt/pimpmykali/
sudo chmod +x /opt/pimpmykali/pimpmykali.sh
cd /opt/pimpmykali/
#sudo ./pimpmykali.sh

# Cloning HotWax - https://github.com/BrashEndeavours/hotwax.git
# ---------------------------------------
echo "\n\n\n Cloning - HotWax \n"
sudo git clone https://github.com/BrashEndeavours/hotwax.git /opt/hotwax/
#cd /opt/hotwax/
#sudo apt install -y git ansible
#sudo ansible-playbook playbook.yml -K

# Install Dev Tools
# ---------------------------------------
# Install Git
echo "\n\n\n Installing - Git \n"
sudo apt-get install -y git 

# Install Perl
echo "\n\n\n Installing - perl \n"
sudo apt-get install -y perl  

# Install Python
echo "\n\n\n Installing - python3 & python \n"
sudo apt-get install -y python3 
sudo apt-get install -y python

echo "\n\n\n Installing - python3-pip& python-pip \n"
sudo apt-get install -y python3-pip 
sudo apt-get install -y python-pip 

sudo python -m pip install --upgrade pip 

# Install Basic Tools
echo "\n\n\n Installing - build-essential \n"
sudo apt-get install -y build-essential 
sudo apt-get install manpages-dev 

# Install Go - https://golang.org/doc/install
echo "\n\n\n Installing - Go \n"
sudo wget -P /opt/ https://golang.org/dl/go1.16.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf /opt/go1.16.linux-amd64.tar.gz
sudo export PATH=$PATH:/usr/local/go/bin

# Install Atom
echo "\n\n\n Installing - Atom \n"
sudo apt-get install -y  software-properties-common apt-transport-https wget
sudo apt-get  install wget gpg
sudo wget -P /opt/ https://atom.io/download/deb
sudo apt-get install -y /opt/atom-amd64.deb

# Install VSCode
echo "\n\n\n Installing - VSCode \n"
sudo wget -q https://packages.microsoft.com/keys/microsoft.asc -O-
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
sudo apt-get install -y code 

# System Tool Install
# ---------------------------------------
echo "\n\n\n Installing - System Tools \n"
sudo apt-get install -y gedit
sudo apt-get install -y tree
sudo apt-get install -y htop
sudo apt-get install -y gedit
sudo apt-get install -y glances

# Hacking Tool Install
# ---------------------------------------
echo "\n\n\n Installing - Hacking Tools \n"
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
sudo apt-get install -y curl 
sudo apt-get install -y nbtscan 
sudo apt-get install -y nmap 
sudo apt-get install -y onesixtyone 
sudo apt-get install -y oscanner 
sudo apt-get install -y smbclient 
sudo apt-get install -y snmp 
sudo apt-get install -y sipvicious 
sudo apt-get install -y tnscmd10g 
sudo apt-get install -y whatweb 
sudo apt-get install -y khtmltopdf 
sudo apt-get install -y smtp-user-enum 
sudo apt-get install -y nishang
sudo apt-get install -y finalrecon


# pip Tool Install
# ---------------------------------------
# Install droopescan - https://github.com/droope/droopescan
echo "\n\n\n Installing - droopescan \n"
sudo pip install droopescan 

echo "\n\n\n Installing - termcolor \n"
sudo pip install termcolor

# Install droopescan - https://github.com/sc0tfree/updog
echo "\n\n\n Installing - updog \n"
sudo pip install updog

# Install droopescan - https://github.com/giampaolo/psutil/blob/master/INSTALL.rst
echo "\n\n\n Installing - psutil \n"
sudo apt-get install gcc python3-dev
sudo pip3 install -U psutil

# Install SysMonTask - https://github.com/KrispyCamel4u/SysMonTask
echo "\n\n\n Installing - SysMonTask \n"
sudo add-apt-repository ppa:camel-neeraj/sysmontask
sudo apt install sysmontask


# Install Reconbot - https://github.com/0bs3ssi0n/Reconbot
echo "\n\n\n Installing - Reconbot \n"
cd /opt/
sudo git clone https://github.com/0bs3ssi0n/Reconbot /opt/Reconbot/
sudo ln -s /opt/Reconbot/reconbot.sh /usr/local/bin/

# Install Impacket - https://github.com/SecureAuthCorp/impacket
echo "\n\n\n Installing - impacket \n"
sudo git clone https://github.com/SecureAuthCorp/impacket.git /opt/impacket/
cd /opt/impacket/
pip install /opt/impacket/.

# Insatll AutoRecon - https://github.com/Tib3rius/AutoRecon#installation
echo "\n\n\n Installing - AutoRecon \n"
sudo python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git 

# install nmapAutomator - https://github.com/21y4d/nmapAutomator
echo "\n\n\n Installing - nmapAutomator \n"
cd /opt/
sudo git clone https://github.com/21y4d/nmapAutomator.git /opt/nmapAutomator/
sudo ln -s /opt/nmapAutomator/nmapAutomator.sh /usr/local/bin/

# Install Chrome
echo "\n\n\n Installing - Chrome \n"
sudo wget -P /opt/ https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb 
sudo apt-get install -y /opt/google-chrome-stable_current_amd64.deb 

# Install Chromium - Doesnt seem to work...
#echo "\n\n\n Installing - chromium-browser \n"
#sudo apt-get install -y chromium-browser 


# Install Terminal Tools + Customization
# ---------------------------------------
echo "\n\n\n Installing - Terminal Tools + Customization \n"
sudo git clone https://github.com/cameronww7/Terminal-Customization /opt/Terminal-Customization/

# Setup my File Strucutres 
sudo mkdir ~/Hacking
sudo chmod -R 777 ~/Hacking  

sudo chmod -R 777 /opt 

# Reboot Prompt
# ---------------------------------------
echo "\n\n\n Finished - REBOOT \n"
