# oooo    oooo           oooo   o8o        .oooooo..o               .                          
# `888   .8P'            `888   `"'       d8P'    `Y8             .o8                          
#  888  d8'     .oooo.    888  oooo       Y88bo.       .ooooo.  .o888oo oooo  oooo  oo.ooooo.  
#  88888[      `P  )88b   888  `888        `"Y8888o.  d88' `88b   888   `888  `888   888' `88b 
#  888`88b.     .oP"888   888   888            `"Y88b 888ooo888   888    888   888   888   888 
#  888  `88b.  d8(  888   888   888       oo     .d8P 888    .o   888 .  888   888   888   888 
# o888o  o888o `Y888""8o o888o o888o      8""88888P'  `Y8bod8P'   "888"  `V88V"V8P'  888bod8P' 
#                                                                                    888       
#                                                                                   o888o      

# Note
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
# Make sure file has needed perms
# chmod +x Kali_Setup.sh

# Update the System
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
echo "\n\n\n System Update"
sudo apt-get clean -y
sudo apt-get update
sudo apt-get full-upgrade -y
sudo apt-get autoremove -y

# Add search cache
sudo apt-get-cache search kali-
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-


# Install VB Guest additions
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
echo "\n\n\n Installing VirtualBox-Guest Additions"
sudo apt-get install -y --reinstall virtualbox-guest-x11
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-


# Installing PipMyKali - https://github.com/Dewalt-arch/pimpmykali
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
echo "\n\n\n Installing - PimyMyKali \n"
sudo git clone https://github.com/Dewalt-arch/pimpmykali /opt/sys_tool_install/pimpmykali/
sudo chmod +x /opt/sys_tool_install/pimpmykali/pimpmykali.sh
cd /opt/sys_tool_install/pimpmykali/
sudo ./pimpmykali.sh --all
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-


# Install Internet Browsers
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
# Install Chrome
echo "\n\n\n Installing - Chrome \n"
sudo wget -P /opt/sys_tool_install/ https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb 
sudo apt-get install -y /opt/sys_tool_install/google-chrome-stable_current_amd64.deb 

# Install Chromium - Doesnt seem to work...
#echo "\n\n\n Installing - chromium-browser \n"
#sudo apt-get install -y chromium-browser 
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-


# Install Office Tools 
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
# Install Libre Office
echo "\n\n\n Installing - Libre Office \n"
sudo apt-get -y install libreoffice
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-


# Install Dev Tools
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
# Install Git - Should already be installed
echo "\n\n\n Installing - Git \n"
sudo apt-get install -y git 

# Install Perl
echo "\n\n\n Installing - perl \n"
sudo apt-get install -y perl  

# Install Python
echo "\n\n\n Installing - python3 & python \n"
sudo apt-get install -y python3 
sudo apt-get install -y python


sudo apt-get install -y python3-pip python3-dev git libssl-dev libffi-dev build-essential

# Install Pip
echo "\n\n\n Installing - python3-pip \n"
sudo apt-get -y --purge autoremove python3-pip
sudo apt-get install -y python3-pip python3-dev git libssl-dev libffi-dev build-essential

# Make sure its upgraded
python3 -m pip install --upgrade pip
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-


# Install Building Tools
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
echo "\n\n\n Installing - build-essential \n"
sudo apt-get install -y build-essential 

echo "\n\n\n Installing - manpages-dev \n"
sudo apt-get install -y manpages-dev

echo "\n\n\n Installing - libpcap-dev \n"
sudo apt-get install -y libpcap-dev

echo "\n\n\n Installing - gcc-mingw-w64 \n"
sudo apt-get install -y gcc-mingw-w64

echo "\n\n\n Installing - default-jdk \n"
sudo apt-get install -y default-jdk
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-


# Installing - Developer/Code Editors
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
# Install Go - https://golang.org/doc/install
echo "\n\n\n Installing - Go \n"
sudo wget -P /opt/sys_tool_install/ https://golang.org/dl/go1.16.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf /opt/sys_tool_install/go1.16.linux-amd64.tar.gz
sudo export GOPATH=$HOME/go
sudo export PATH=$PATH:/usr/local/go/bin

# Install Atom
echo "\n\n\n Installing - Atom \n"
sudo apt-get install -y  software-properties-common apt-transport-https wget
sudo apt-get install wget gpg
sudo wget -P /opt/sys_tool_install/ https://atom.io/download/deb
sudo apt-get install -y /opt/sys_tool_install/atom-amd64.deb

# Install VSCode
echo "\n\n\n Installing - VSCode \n"
sudo apt-get install -y software-properties-common apt-transport-https wget
sudo wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
sudo apt-get update
sudo apt-get install -y code 
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-


# Basic/Other Tools Install
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
echo "\n\n\n Installing - Basic/Other Tools \n"
sudo apt-get install -y gedit
sudo apt-get install -y tree
sudo apt-get install -y htop
sudo apt-get install -y gedit
sudo apt-get install -y glances
sudo apt-get install -y most
sudo apt-get install -y ssh
sudo apt-get install -y rdesktop
sudo apt-get install -y freerdp-x11
sudo apt-get install -y ansible
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-


# Hacking Tools & Dependencies Install
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
echo "\n\n\n Installing - Hacking Tools & Dependencies \n"
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
sudo apt-get install -y feroxbuster
sudo apt-get install -y impacket-scripts
sudo apt-get install -y redis-tools
sudo apt-get install -y snmpwalk
sudo apt-get install -y svwar
sudo apt-get install -y wkhtmltopdf

# Install python-xlrd
# Windows-Exploit-Suggester dependencies
echo "\n\n\n Installing - python-xlrd \n"
install python-xlrd, $ pip install xlrd --upgrade
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-


# searchsploit Tool Install
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
# Install searchsploit
echo "\n\n\n Installing - searchsploit \n"
sudo apt update && sudo apt -y install exploitdb

echo "\n\n\n Installing - upgrading \n"
searchsploit -u
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-


# Installing - pip Tools
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
echo "\n\n\n Installing - termcolor \n"
sudo pip3 install termcolor

echo "\n\n\n Installing - badchars \n"
sudo pip install badchars

echo "\n\n\n Installing - requests \n"
sudo pip install requests
sudo pip3 install requests

echo "\n\n\n Installing - dnspython \n"
sudo pip install dnspython

echo "\n\n\n Installing - argparse \n"
sudo pip install argparse

# Install psutil - https://github.com/giampaolo/psutil/blob/master/INSTALL.rst
echo "\n\n\n Installing - psutil \n"
sudo apt-get install gcc python3-dev
sudo pip3 install -U psutil

# Install Pwn Tools
echo "\n\n\n Installing - argparse \n"
sudo python3 -m pip install --upgrade pwntools
python3 -m pip install --upgrade pwntools
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-

# Install CyberChef 
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
echo "\n\n\n Installing - CyberChef \n"
sudo mkdir /opt/CyberChef
sudo wget -P /opt/CyberChef/ https://github.com/gchq/CyberChef/releases/download/v9.32.3/CyberChef_v9.32.3.zip
cd /opt/CyberChef
sudo unzip -d CyberChef_v9.32.3.zip /opt/CyberChef/CyberChef_v9.32.3.zip
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-

# Installing - Enumeration Tools
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
# Insatll AutoRecon - https://github.com/Tib3rius/AutoRecon#installation
echo "\n\n\n Installing - AutoRecon \n"
sudo python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git

# install nmapAutomator - https://github.com/21y4d/nmapAutomator
echo "\n\n\n Installing - nmapAutomator \n"
cd /opt/
sudo git clone https://github.com/21y4d/nmapAutomator.git /opt/_Tools/nmapAutomator/
# Creates a Symbolic Link to the file so you can call it from anywhere
sudo ln -s /opt/_Tools/nmapAutomator/nmapAutomator.sh /usr/local/bin/

# Install Reconbot - https://github.com/0bs3ssi0n/Reconbot
echo "\n\n\n Installing - Reconbot \n"
cd /opt/
sudo git clone https://github.com/0bs3ssi0n/Reconbot /opt/_Tools/Reconbot/
# Creates a Symbolic Link to the file so you can call it from anywhere
sudo ln -s /opt/_Tools/Reconbot/reconbot.sh /usr/local/bin/

# install naabu - https://github.com/projectdiscovery/naabu.git
echo "\n\n\n Installing - naabu \n"
git clone https://github.com/projectdiscovery/naabu.git /opt/_Tools/naabu; cd /_Tools/opt/naabu/v2/cmd/naabu; go build; cp naabu /usr/local/bin/; naabu -version

# Install droopescan - https://github.com/droope/droopescan
echo "\n\n\n Installing - droopescan \n"
sudo pip install droopescan 
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-


# Install Terminal Tools + Customization
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
echo "\n\n\n Installing - Terminal Tools + Customization \n"
sudo git clone https://github.com/cameronww7/Terminal-Customization /opt/Terminal-Customization/
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-


# Clone Useful Priv Esc Tools to Opt
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
# ooooooooo.             o8o                   oooooooooooo                    
# `888   `Y88.           `"'                   `888'     `8                    
#  888   .d88' oooo d8b oooo  oooo    ooo       888          .oooo.o  .ooooo.  
#  888ooo88P'  `888""8P `888   `88.  .8'        888oooo8    d88(  "8 d88' `"Y8 
#  888          888      888    `88..8'         888    "    `"Y88b.  888       
#  888          888      888     `888'          888       o o.  )88b 888   .o8 
# o888o        d888b    o888o     `8'          o888ooooood8 8""888P' `Y8bod8P' 

echo "\n\n\n Installing - Priv Esc File Structure \n"
sudo mkdir /opt/__PRIV_ESC

sudo mkdir /opt/__PRIV_ESC/_WINDOWS
sudo mkdir /opt/__PRIV_ESC/_WINDOWS/_EXECUTABLE
sudo mkdir /opt/__PRIV_ESC/_WINDOWS/_POWERSHELL
sudo mkdir /opt/__PRIV_ESC/_WINDOWS/_OTHER

sudo mkdir /opt/__PRIV_ESC/_LINUX


echo "\n\n\n Installing - Win/Lin Priv Esc Scripts \n"

echo "\n\n\n Installing - AlessandroZ/BeRoot \n"
sudo git clone https://github.com/AlessandroZ/BeRoot.git /opt/__PRIV_ESC/BeRoot-AlessandroZ


# ooooo         o8o                                      
# `888'         `"'                                      
#  888         oooo  ooo. .oo.   oooo  oooo  oooo    ooo 
#  888         `888  `888P"Y88b  `888  `888   `88b..8P'  
#  888          888   888   888   888   888     Y888'    
#  888       o  888   888   888   888   888   .o8"'88b   
# o888ooooood8 o888o o888o o888o  `V88V"V8P' o88'   888o 

echo "\n\n\n Installing - Linux Priv Esc Scripts \n"

echo "\n\n\n Installing - carlospolop/linPEAS \n"
sudo mkdir /opt/__PRIV_ESC/_LINUX/0-Start_linPEAS-carlospolop
sudo wget https://github.com/carlospolop/PEASS-ng/releases/download/20220901/linpeas.sh  /opt/__PRIV_ESC/_LINUX/0-Start_linPEAS-carlospolop/

echo "\n\n\n Installing - LinEnum \n"
sudo git clone https://github.com/rebootuser/LinEnum.git /opt/__PRIV_ESC/_LINUX/1_LinEnum-rebootuser

echo "\n\n\n Installing - Citadel \n"
sudo git clone https://github.com/redcode-labs/Citadel.git /opt/__PRIV_ESC/_LINUX/Citadel-redcode-labs

echo "\n\n\n Installing - Bashark \n"
sudo git clone https://github.com/redcode-labs/Bashark /opt/__PRIV_ESC/_LINUX/Bashark-redcode-labs

echo "\n\n\n Installing - linux-exploit-suggester \n"
sudo git clone https://github.com/mzet-/linux-exploit-suggester.git /opt/__PRIV_ESC/_LINUX/2_linux-exploit-suggester-mzet-

echo "\n\n\n Installing - linuxprivchecker-Py \n"
sudo git clone https://github.com/sleventyeleven/linuxprivchecker.git /opt/__PRIV_ESC/_LINUX/linuxprivchecker-Py-sleventyeleven

echo "\n\n\n Installing - linux-smart-enumeration \n"
sudo git clone https://github.com/diego-treitos/linux-smart-enumeration.git /opt/__PRIV_ESC/_LINUX/linux-smart-enumeration-diego-treitos

echo "\n\n\n Installing - ohpe/juicy-potato \n"
sudo git clone https://github.com/ohpe/juicy-potato.git /opt/__PRIV_ESC/_LINUX/juicy-potato-ohpe


# oooooo   oooooo     oooo  o8o                    .o8                                      
#  `888.    `888.     .8'   `"'                   "888                                      
#   `888.   .8888.   .8'   oooo  ooo. .oo.    .oooo888   .ooooo.  oooo oooo    ooo  .oooo.o 
#    `888  .8'`888. .8'    `888  `888P"Y88b  d88' `888  d88' `88b  `88. `88.  .8'  d88(  "8 
#     `888.8'  `888.8'      888   888   888  888   888  888   888   `88..]88..8'   `"Y88b.  
#      `888'    `888'       888   888   888  888   888  888   888    `888'`888'    o.  )88b 
#       `8'      `8'       o888o o888o o888o `Y8bod88P" `Y8bod8P'     `8'  `8'     8""888P' 

echo "\n\n\n Installing - Windows Priv Esc Scripts \n"

echo "\n\n\n Installing - carlospolop/winPEAS \n"
sudo mkdir /opt/__PRIV_ESC/_WINDOWS/0-Start_winPEAS-carlospolop
sudo wget https://github.com/carlospolop/PEASS-ng/releases/download/20220901/winPEAS.bat     /opt/__PRIV_ESC/_WINDOWS/0-Start_winPEAS-carlospolop/
sudo wget https://github.com/carlospolop/PEASS-ng/releases/download/20220901/winPEASx64.exe  /opt/__PRIV_ESC/_WINDOWS/0-Start_winPEAS-carlospolop/
sudo wget https://github.com/carlospolop/PEASS-ng/releases/download/20220901/winPEASx86.exe  /opt/__PRIV_ESC/_WINDOWS/0-Start_winPEAS-carlospolop/

echo "\n\n\n Installing - AonCyberLabs/Windows-Exploit-Suggester-AonCyberLabs \n"
sudo git clone https://github.com/AonCyberLabs/Windows-Exploit-Suggester.git /opt/__PRIV_ESC/_WINDOWS/_OTHER/Windows-Exploit-Suggester-AonCyberLabs

cd /opt/__PRIV_ESC/_WINDOWS/_OTHER/
touch howToUpdateWindowsExploiter.txt
echo "./windows-exploit-suggester.py --update" >> howToUpdateWindowsExploiter.txt
echo "./windows-exploit-suggester.py --database 2014-06-06-mssb.xlsx --systeminfo win7sp1-systeminfo.txt" >> howToUpdateWindowsExploiter.txt

echo "\n\n\n Installing - pentestmonkey/windows-privesc-check-pentestmonkey \n"
sudo git clone https://github.com/pentestmonkey/windows-privesc-check.git /opt/__PRIV_ESC/_WINDOWS/_OTHER/windows-privesc-check-pentestmonkey

echo "\n\n\n Installing - absolomb/WindowsEnu-absolomb \n"
sudo git clone https://github.com/absolomb/WindowsEnum.git /opt/__PRIV_ESC/_WINDOWS/2_WindowsEnum-absolomb

echo "\n\n\n Installing - M4ximuss/Powerless-M4ximuss \n"
sudo git clone https://github.com/M4ximuss/Powerless.git /opt/__PRIV_ESC/_WINDOWS/_OTHER/Powerless-M4ximuss

echo "\n\n\n Installing - bitsadmin/wesngn-bitsadmin \n"
sudo git clone https://github.com/bitsadmin/wesng.git /opt/__PRIV_ESC/_WINDOWS/_OTHER/wesng-bitsadmin

echo "\n\n\n Installing - rasta-mouse/Sherlock-rasta-mouse \n"
sudo git clone https://github.com/rasta-mouse/Sherlock.git /opt/__PRIV_ESC/_WINDOWS/_POWERSHELL/Sherlock-rasta-mouse

echo "\n\n\n Installing - rasta-mouse/Watson-rasta-mouse \n"
sudo git clone https://github.com/rasta-mouse/Watson.git /opt/__PRIV_ESC/_WINDOWS/_EXECUTABLE/Watson-rasta-mouse

echo "\n\n\n Installing - WindowsExploits-abatchy17 \n"
sudo git clone https://github.com/abatchy17/WindowsExploits.git /opt/__PRIV_ESC/_WINDOWS/_OTHER/WindowsExploits-abatchy17

echo "\n\n\n Installing - Windows-Exploit-Suggester-2-7Ragnarok7 \n"
sudo git clone https://github.com/7Ragnarok7/Windows-Exploit-Suggester-2.git /opt/__PRIV_ESC/_WINDOWS/1_Windows-Exploit-Suggester-2-7Ragnarok7

echo "\n\n\n Installing - PowerSploi-PowerShellMafia \n"
sudo git clone https://github.com/PowerShellMafia/PowerSploit/tree/master/Privesc /opt/__PRIV_ESC/_WINDOWS/_POWERSHELL/PowerSploit-PowerShellMafia

echo "\n\n\n Installing - Windows-Privilege-Escalation-frizb \n"
sudo git clone https://github.com/frizb/Windows-Privilege-Escalation /opt/__PRIV_ESC/_WINDOWS/_OTHER/Windows-Privilege-Escalation-frizb

echo "\n\n\n Installing - windows-kernel-exploits-SecWiki \n"
sudo git clone https://github.com/SecWiki/windows-kernel-exploits /opt/__PRIV_ESC/_WINDOWS/_OTHER/windows-kernel-exploits-SecWiki

echo "\n\n\n Installing - windows-GhostPack/SharpUp \n"
sudo git clone https://github.com/GhostPack/SharpUp /opt/__PRIV_ESC/_WINDOWS/_EXECUTABLE/windows-SharpUp-GhostPack

echo "\n\n\n Installing - windows-GhostPack/Seatbelti \n"
sudo git clone https://github.com/GhostPack/Seatbelt /opt/__PRIV_ESC/_WINDOWS/_EXECUTABLE/Seatbelti-GhostPack

echo "\n\n\n Installing - windows-411Hall/JAWS \n"
sudo git clone https://github.com/411Hall/JAWS /opt/__PRIV_ESC/_WINDOWS/_POWERSHELL/JAWS-411Hall
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-


#   .oooooo.       .   oooo                           
#  d8P'  `Y8b    .o8   `888                           
# 888      888 .o888oo  888 .oo.    .ooooo.  oooo d8b 
# 888      888   888    888P"Y88b  d88' `88b `888""8P 
# 888      888   888    888   888  888ooo888  888     
# `88b    d88'   888 .  888   888  888    .o  888     
#  `Y8bood8P'    "888" o888o o888o `Y8bod8P' d888b    
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
echo "\n\n\n Installing - Other Useful Scripts \n"
sudo mkdir /opt/_Payload_Scripts

echo "\n\n\n Installing - swisskyrepo/PayloadsAllTheThings \n"
sudo git clone https://github.com/swisskyrepo/PayloadsAllTheThings.git /opt/_Payload_Scripts/PayloadsAllTheThings-swisskyrepo

echo "\n\n\n Installing - g0tmi1k/msfpc \n"
sudo git clone https://github.com/g0tmi1k/msfpc /opt/_Payload_Scripts/MSFvenom-Payload-Creator-g0tmi1k

echo "\n\n\n Installing - ShutdownRepo/shellerator \n"
sudo git clone https://github.com/ShutdownRepo/shellerator.git /opt/_Payload_Scripts/shellerator-ShutdownRepo

echo "\n\n\n Installing - Gr1mmie/sumrecon \n"
sudo git clone https://github.com/Gr1mmie/sumrecon.git /opt/_Payload_Scripts/sumrecon-Gr1mmie

echo "\n\n\n Installing - danielmiessler/SecLists \n"
sudo git clone https://github.com/danielmiessler/SecLists /opt/_Payload_Scripts/SecLists-danielmiessler

echo "\n\n\n Installing - pwncat \n"
sudo pip install git+https://github.com/calebstewart/pwncat.git

echo "\n\n\n Installing - gimmeSH \n"
cd /opt/
sudo git clone https://github.com/A3h1nt/gimmeSH /opt/_Tools/gimmeSH/
# Creates a Symbolic Link to the file so you can call it from anywhere
sudo ln -s /opt/gimmeSH/gimmeSH.sh /usr/_Tools/local/bin/

# Install Impacket - https://github.com/SecureAuthCorp/impacket
echo "\n\n\n Installing - impacket \n"
sudo git clone https://github.com/SecureAuthCorp/impacket.git /opt/_Tools/impacket/
cd /opt/impacket/
sudo pip install /opt/impacket/.

echo "\n\n\n Installing - tomnomnom/assetfinder \n"
go get -u github.com/tomnomnom/assetfinder
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-

# Build Out Mega Dir Busting File 
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
sort -u /usr/share/seclists/Discovery/Web-Content/{big.txt,common.txt,directory-list-2.3*,raft-large-directories.txt,raft-large-files.txt,raft-medium-directories.txt,raft-medium-files.txt,raft-small-directories.txt,RobotsDisallowed-Top1000.txt} > mega-dirbuster.txt
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-

# Unpack & Fixing Rockyou not being UTF8 (SO ANNOYING)
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
sudo tar -xzvf /usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt.tar.gz

sudo iconv -f ISO-8859-1 -t UTF-8//TRANSLIT /usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt -o /usr/share/seclists/Passwords/Leaked-Databases/rockyou-UTF8.txt
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-


# Setup my File Strucutres 
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
sudo mkdir ~/Hacking
sudo chmod -R 777 ~/Hacking  
sudo chmod -R 777 /opt 
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-


# Adding password feedback
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
echo "\n\n\n Installing - password feedback \n"
echo "" | sudo EDITOR='tee -a' visudo # Adds a Newline to the File
echo "Defaults	pwfeedback" | sudo EDITOR='tee -a' visudo
echo "" | sudo EDITOR='tee -a' visudo # Adds a Newline to the File
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-

# Add Sudo Lecture Message
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
# https://www.cyberciti.biz/open-source/command-line-hacks/adding-spice-to-your-sudo-session-with-a-lecture-file-on-linux-or-unix/
# https://stackoverflow.com/questions/323957/how-do-i-edit-etc-sudoers-from-a-script
echo "\n\n\n Installing - Sudo Lecture Message \n"

sudo cp /opt/Linux-System-Setup/OSCP_VM_Setup/sudo_lecture.txt /etc/sudo_lecture.txt

echo "\n\n\n Adding Sudo Lecture Message \n"
echo "" | sudo EDITOR='tee -a' visudo # Adds a Newline to the File
echo "# Adding Lecture Message" | sudo EDITOR='tee -a' visudo
echo "#~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-" | sudo EDITOR='tee -a' visudo
echo "Defaults	lecture=always" | sudo EDITOR='tee -a' visudo
echo "Defaults	lecture_file=/etc/sudo_lecture.txt" | sudo EDITOR='tee -a' visudo
echo "" | sudo EDITOR='tee -a' visudo # Adds a Newline to the File
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-


# Final Update Check
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
echo "\n\n\n Updating - RUnning FInal UPDATE CHECK! \n"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-

# Clean up
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
sudo cd /opt/
sudo rm -rf google
sudo rm -rf requets
sudo rm -rf /opt/sys_tool_install
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-

# Reboot Prompt
# ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~--~-~-~-~-~--~-~-~-~-~--~-~-~-~-~-
echo "\n\n\n FINISHED - REBOOTING IN 60 Seconds !\n"
echo "\n\n\n FINISHED - REBOOTING IN 60 Seconds !\n"
echo "\n\n\n FINISHED - REBOOTING IN 60 Seconds !\n"
sleep 60
reboot