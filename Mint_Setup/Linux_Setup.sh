# Note
# ---------------------------------------
# Make sure file has needed perms
# chmod +x Linux_Setup.sh

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

echo "\n\n\n Installing - python3-pip & python-pip \n"
sudo apt-get install -y python3-pip 
sudo apt-get install -y python-pip 

sudo python -m pip3 install --upgrade pip3

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
sudo chmod -R 755 /opt 

# Add Sudo Lecture Message
# ---------------------------------------
# https://www.cyberciti.biz/open-source/command-line-hacks/adding-spice-to-your-sudo-session-with-a-lecture-file-on-linux-or-unix/
# https://stackoverflow.com/questions/323957/how-do-i-edit-etc-sudoers-from-a-script

sudo cp sudo_lecture.txt /etc/sudo_lecture.txt

echo "\n\n\n Adding Sudo Lecture Message \n"
echo "" | sudo EDITOR='tee -a' visudo
echo "# Adding Lecture Message" | sudo EDITOR='tee -a' visudo
echo "#---------------------------------------" | sudo EDITOR='tee -a' visudo
echo "Defaults	lecture=always" | sudo EDITOR='tee -a' visudo
echo "Defaults	lecture_file=/etc/sudo_lecture.txt" | sudo EDITOR='tee -a' visudo
echo "" | sudo EDITOR='tee -a' visudo

# Reboot Prompt
# ---------------------------------------
echo "\n\n\n Finished - REBOOT \n"
