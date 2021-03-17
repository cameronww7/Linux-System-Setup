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

# pip Tool Install
# ---------------------------------------
echo "\n\n\n Updating - termcolor \n"
sudo pip install termcolor -U

# Install droopescan - https://github.com/sc0tfree/updog
echo "\n\n\n Updating - updog \n"
sudo pip install updog -U

# Install droopescan - https://github.com/giampaolo/psutil/blob/master/INSTALL.rst
echo "\n\n\n Updating - psutil \n"
sudo pip3 install psutil -U

# Install Terminal Tools + Customization
# ---------------------------------------
echo "\n\n\n Updating - Terminal Tools + Customization \n"
cd /opt/Terminal-Customization/
sudo git fetch -A
sudo git pull

sudo ./opt/Terminal-Customization/Mint/manual_update.sh

# Setup my File Strucutres 
sudo mkdir ~/Hacking
sudo chmod -R 777 ~/Hacking  

sudo chmod -R 777 /opt 

# Reboot Prompt
# ---------------------------------------
echo "\n\n\n Finished - REBOOT \n"
