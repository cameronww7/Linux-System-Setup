# Note
# ---------------------------------------
# Make sure file has needed perms
# chmod +x terminal_setup.sh

sudo touch /opt/kali_install_logs.txt
cd /opt/


echo "\n Update + Install Basics"
echo "\n Update + Install Basics" >> /opt/kali_install_logs.txt

# Install VB Guest additions
# ---------------------------------------
sudo apt update >> /opt/kali_install_logs.txt
sudo apt install -y --reinstall virtualbox-guest-x11 >> /opt/kali_install_logs.txt


# Update the System
# ---------------------------------------
sudo apt clean -y >> /opt/kali_install_logs.txt
sudo apt upgrade -y >> /opt/kali_install_logs.txt
sudo apt dist-upgrade -y >> /opt/kali_install_logs.txt
sudo apt autoremove -y >> /opt/kali_install_logs.txt

# Install Video Drivers
sudo apt install -y ocl-icd-libopencl1 nvidia-driver nvidia-cuda-toolkit >> /opt/kali_install_logs.txt

# Add search cache
sudo apt-cache search kali- >> /opt/kali_install_logs.txt

# Install PipMyKali - https://github.com/Dewalt-arch/pimpmykali
# ---------------------------------------
echo "\n Installing - PimyMyKali"
echo "\n Installing - PimyMyKali" >> /opt/kali_install_logs.txt
sudo git clone https://github.com/Dewalt-arch/pimpmykali /opt/
sudo chmod +x /opt/pimpmykali/pimpmykali.sh
cd /opt/pimpmykali/
sudo ./pimpmykali/pimpmykali.sh >> /opt/kali_install_logs.txt

# Install Dev Tools
# ---------------------------------------
# Install Git
echo "\n Installing - Git"
echo "\n Installing - Git" >> /opt/kali_install_logs.txt
sudo apt install -y git 

# Install Perl
echo "\n Installing - perl"
echo "\n Installing - perl" >> /opt/kali_install_logs.txt
sudo apt install -y perl  

# Install Python
echo "\n Installing - python3"
echo "\n Installing - python3-pip" >> /opt/kali_install_logs.txt
sudo apt install -y python3 
sudo apt install -y python3-pip 

echo "\n Installing - python"
echo "\n Installing - python-pip" >> /opt/kali_install_logs.txt
sudo apt install -y python  
sudo apt install -y python-pip 

# Install Basic Tools
echo "\n Installing - build-essential "
echo "\n Installing - build-essential " >> /opt/kali_install_logs.txt
sudo apt install -y build-essential 
sudo apt-get install manpages-dev 

# Install Go - https://golang.org/doc/install
echo "\n Installing - Go"
echo "\n Installing - Go" >> /opt/kali_install_logs.txt
sudo wget -P /opt/ https://golang.org/dl/go1.16.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf /opt/go1.16.linux-amd64.tar.gz
sudo export PATH=$PATH:/usr/local/go/bin

# Install Atom
echo "\n Installing - Atom"
echo "\n Installing - Atom" >> /opt/kali_install_logs.txt
sudo apt install -y  software-properties-common apt-transport-https wget
sudo apt  install wget gpg
sudo wget /opt/ https://atom.io/download/deb
sudo apt install -y /opt/atom-amd64.deb

# Install VSCode
echo "\n Installing - VSCode"
echo "\n Installing - VSCode" >> /opt/kali_install_logs.txt
sudo wget -q https://packages.microsoft.com/keys/microsoft.asc -O-
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
sudo apt install -y code 


# Tool Install
# ---------------------------------------
echo "\n Installing - gedit"
echo "\n Installing - gedit" >> /opt/kali_install_logs.txt
sudo apt install -y gedit 

echo "\n Installing - gobuster"
echo "\n Installing - gobuster" >> /opt/kali_install_logs.txt
sudo apt install -y gobuster 

echo "\n Installing - sslscan"
echo "\n Installing - sslscan" >> /opt/kali_install_logs.txt
sudo apt install -y sslscan 

echo "\n Installing - nikto"
echo "\n Installing - nikto" >> /opt/kali_install_logs.txt
sudo apt install -y nikto 

echo "\n Installing - joomscan"
echo "\n Installing - joomscan" >> /opt/kali_install_logs.txt
sudo apt install -y joomscan 

echo "\n Installing - wpscan"
echo "\n Installing - wpscan" >> /opt/kali_install_logs.txt
sudo apt install -y wpscan 

echo "\n Installing - smbmap"
echo "\n Installing - smbmap" >> /opt/kali_install_logs.txt
sudo apt install -y smbmap 

echo "\n Installing - enum4linux"
echo "\n Installing - enum4linux" >> /opt/kali_install_logs.txt
sudo apt install -y enum4linux

echo "\n Installing - dnsrecon"
echo "\n Installing - dnsrecon" >> /opt/kali_install_logs.txt
sudo apt install -y dnsrecon 

echo "\n Installing - odat"
echo "\n Installing - odat" >> /opt/kali_install_logs.txt
sudo apt install -y odat 

echo "\n Installing - seclists"
echo "\n Installing - seclists" >> /opt/kali_install_logs.txt
sudo apt install -y seclists 

echo "\n Installing - ffuf"
echo "\n Installing - ffuf" >> /opt/kali_install_logs.txt
sudo apt install -y ffuf 

echo "\n Installing - seclists"
echo "\n Installing - seclists" >> /opt/kali_install_logs.txt
sudo apt install -y seclists 

echo "\n Installing - curl"
echo "\n Installing - curl" >> /opt/kali_install_logs.txt
sudo apt install -y curl 

echo "\n Installing - nbtscan"
echo "\n Installing - nbtscan" >> /opt/kali_install_logs.txt
sudo apt install -y nbtscan 

echo "\n Installing - nmap"
echo "\n Installing - nmap" >> /opt/kali_install_logs.txt
sudo apt install -y nmap 

echo "\n Installing - onesixtyone"
echo "\n Installing - onesixtyone" >> /opt/kali_install_logs.txt
sudo apt install -y onesixtyone 

echo "\n Installing - oscanner"
echo "\n Installing - oscanner" >> /opt/kali_install_logs.txt
sudo apt install -y oscanner 

echo "\n Installing - smbclient"
echo "\n Installing - smbclient" >> /opt/kali_install_logs.txt
sudo apt install -y smbclient 

echo "\n Installing - snmp"
echo "\n Installing - snmp" >> /opt/kali_install_logs.txt
sudo apt install -y snmp 

echo "\n Installing - sslscan"
echo "\n Installing - sslscan" >> /opt/kali_install_logs.txt
sudo apt install -y sslscan 

echo "\n Installing - sipvicious"
echo "\n Installing - sipvicious" >> /opt/kali_install_logs.txt
sudo apt install -y sipvicious 

echo "\n Installing - tnscmd10g"
echo "\n Installing - tnscmd10g" >> /opt/kali_install_logs.txt
sudo apt install -y tnscmd10g 

echo "\n Installing - whatweb"
echo "\n Installing - whatweb" >> /opt/kali_install_logs.txt
sudo apt install -y whatweb 

echo "\n Installing - khtmltopdf"
echo "\n Installing - khtmltopdf" >> /opt/kali_install_logs.txt
sudo apt install -y khtmltopdf 

echo "\n Installing - smtp-user-enum"
echo "\n Installing - smtp-user-enum" >> /opt/kali_install_logs.txt
sudo apt install -y smtp-user-enum 

# Install droopescan - https://github.com/droope/droopescan
echo "\n Installing - droopescan"
echo "\n Installing - droopescan" >> /opt/kali_install_logs.txt
sudo pip install droopescan 

# Insatll AutoRecon - https://github.com/Tib3rius/AutoRecon#installation
echo "\n Installing - AutoRecon"
echo "\n Installing - AutoRecon" >> /opt/kali_install_logs.txt
sudo python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git 

# install nmapAutomator - https://github.com/21y4d/nmapAutomator
echo "\n Installing - nmapAutomator"
echo "\n Installing - nmapAutomator" >> /opt/kali_install_logs.txt
cd /opt/
sudo git clone https://github.com/21y4d/nmapAutomator.git /opt/
sudo ln -s /opt/nmapAutomator/nmapAutomator.sh /usr/local/bin/

# Install Chrome
echo "\n Installing - Chrome"
echo "\n Installing - Chrome" >> /opt/kali_install_logs.txt
sudo wget -P /opt/ https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb 
sudo apt install -y /opt/google-chrome-stable_current_amd64.deb 

# Install Chromium - Doesnt seem to work...
#echo "\n Installing - chromium-browser "
#echo "\n Installing - chromium-browser " >> /opt/kali_install_logs.txt
#sudo apt install -y chromium-browser 


# Install Terminal Tools + Customization
# ---------------------------------------
echo "\n Installing - Terminal Tools + Customization"
echo "\n Installing - Terminal Tools + Customization" >> /opt/kali_install_logs.txt
sudo git clone https://github.com/cameronww7/Terminal-Customization /opt/
sudo chmod +x /opt/Terminal-Customization/kali/terminal_setup.sh
cd /opt/Terminal-Customization/kali/
sudo ./kali_terminal_setup.sh


# Reboot
# ---------------------------------------
echo "\n Installing - reboot"
echo "\n Installing - reboot" >> /opt/kali_install_logs.txt
reboot