# Note
# ---------------------------------------
# Make sure file has needed perms
# chmod +x Kali_Setup.sh

echo "\n\n\n Update + Install Basics"

# Update the System
# ---------------------------------------
sudo apt-get update
sudo apt-get clean -y
sudo apt-get full-upgrade -y
sudo apt-get autoremove -y

# Add search cache
sudo apt-get-cache search kali-

# Cloning PipMyKali - https://github.com/Dewalt-arch/pimpmykali
# ---------------------------------------
echo "\n\n\n Updating - PimyMyKali \n"
cd /opt/pimpmykali/
sudo git fetch -A
sudo git pull

# Cloning HotWax - https://github.com/BrashEndeavours/hotwax.git
# ---------------------------------------
echo "\n\n\n Updating - HotWax \n"
cd /opt/hotwax/
sudo git fetch -A
sudo git pull


# pip Tool Install
# ---------------------------------------
# Install droopescan - https://github.com/droope/droopescan
echo "\n\n\n Updating - droopescan \n"
sudo pip install droopescan -U

echo "\n\n\n Updating - termcolor \n"
sudo pip install termcolor -U

# Install droopescan - https://github.com/giampaolo/psutil/blob/master/INSTALL.rst
echo "\n\n\n Updating - psutil \n"
sudo pip3 install psutil -U

# Install Reconbot - https://github.com/0bs3ssi0n/Reconbot
echo "\n\n\n Updating - Reconbot \n"
cd /opt/Reconbot/
sudo git fetch -A
sudo git pull

# Install Impacket - https://github.com/SecureAuthCorp/impacket
echo "\n\n\n Updating - impacket \n"
cd /opt/impacket/
sudo git fetch -A
sudo git pull

# Insatll AutoRecon - https://github.com/Tib3rius/AutoRecon#installation
echo "\n\n\n Updating - AutoRecon \n"
sudo python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git 

# install nmapAutomator - https://github.com/21y4d/nmapAutomator
echo "\n\n\n Updating - nmapAutomator \n"
cd /opt/nmapAutomator/
sudo git fetch -A
sudo git pull


# Install Terminal Tools + Customization
# ---------------------------------------
echo "\n\n\n Updating - Terminal Tools + Customization \n"
cd /opt/Terminal-Customization/
sudo git fetch -A
sudo git pull

sudo ./opt/Terminal-Customization/Kali/manual_update.sh

# Setup my File Strucutres 
sudo mkdir ~/Hacking
sudo chmod -R 777 ~/Hacking  

sudo chmod -R 777 /opt 

# Reboot Prompt
# ---------------------------------------
echo "\n\n\n Finished - REBOOT \n"
