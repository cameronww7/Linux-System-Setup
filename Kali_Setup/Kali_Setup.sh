#!/usr/bin/env bash
# Kali_Setup.sh - provisions a Kali Linux pentest box: recon/enum tools,
# priv-esc script tree, payload scripts. Does NOT install desktop
# productivity apps - see Gnome_Setup/Fedora_Setup for that.
#
# Usage: ./Kali_Setup.sh
# Run as a normal user (not with sudo) - individual privileged steps sudo
# internally. Safe to re-run: every step checks whether it's already done
# before installing/adding/cloning anything again. Shell/terminal
# customization (oh-my-zsh, zsh plugins, powerlevel10k, .zshrc) is fully
# delegated to the Terminal-Customization repo cloned below - this script
# does not touch zsh at all.

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "[x] Run this script as your normal user, not with sudo. It sudos internally as needed." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$REPO_ROOT/lib/common.sh"

# --- apt-specific idempotency helpers (mirrors Gnome_Setup.sh) ------------

apt_install_if_missing() {
    local missing=()
    for pkg in "$@"; do
        dpkg -s "$pkg" &>/dev/null || missing+=("$pkg")
    done
    if ((${#missing[@]})); then
        log_info "Installing: ${missing[*]}"
        sudo apt-get install -y "${missing[@]}"
    else
        log_info "Already installed, skipping: $*"
    fi
}

apt_add_keyring_bin() {
    local key_url="$1" keyring="$2"
    if [[ ! -f "$keyring" ]]; then
        log_info "Adding keyring: $keyring"
        sudo curl -fsSLo "$keyring" "$key_url"
    fi
}

apt_add_keyring_asc() {
    local key_url="$1" keyring="$2"
    if [[ ! -f "$keyring" ]]; then
        log_info "Adding keyring: $keyring"
        curl -fsSL "$key_url" | gpg --dearmor | sudo tee "$keyring" >/dev/null
    fi
}

apt_add_source_list() {
    local list_file="$1" deb_line="$2"
    if [[ ! -f "$list_file" ]] || ! grep -qF "$deb_line" "$list_file"; then
        log_info "Adding apt source: $list_file"
        echo "$deb_line" | sudo tee "$list_file" >/dev/null
        sudo apt-get update
    fi
}

# $1 = package name to check, $2 = install spec (pypi name, or git+URL / package name if different)
pip_install_if_missing() {
    local pkg="$1" install_spec="${2:-$1}"
    if python3 -m pip show "$pkg" &>/dev/null; then
        log_info "$pkg already installed (pip), skipping"
    else
        log_info "Installing (pip): $pkg"
        sudo python3 -m pip install "$install_spec"
    fi
}

# ---------------------------------------------------------------------------
# 1. System update
# ---------------------------------------------------------------------------
log_info "System update"
sudo apt-get update
sudo apt-get full-upgrade -y
sudo apt-get autoremove -y

# ---------------------------------------------------------------------------
# 2. PimpMyKali - https://github.com/Dewalt-arch/pimpmykali
# ---------------------------------------------------------------------------
log_info "PimpMyKali"
ensure_opt_dir
git_clone_or_update "https://github.com/Dewalt-arch/pimpmykali" /opt/sys_tool_install/pimpmykali
chmod +x /opt/sys_tool_install/pimpmykali/pimpmykali.sh
(cd /opt/sys_tool_install/pimpmykali && sudo ./pimpmykali.sh --all)

# ---------------------------------------------------------------------------
# 3. Browsers
# ---------------------------------------------------------------------------
log_info "Brave browser"
apt_add_keyring_bin "https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg" /usr/share/keyrings/brave-browser-archive-keyring.gpg
apt_add_source_list /etc/apt/sources.list.d/brave-browser-release.list \
    "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"
apt_install_if_missing brave-browser

# ---------------------------------------------------------------------------
# 4. Office tools
# ---------------------------------------------------------------------------
log_info "LibreOffice"
apt_install_if_missing libreoffice

# ---------------------------------------------------------------------------
# 5. Build/dev toolchain
# ---------------------------------------------------------------------------
log_info "Build/dev toolchain"
apt_install_if_missing build-essential manpages-dev libpcap-dev libffi-dev libssl-dev gcc-mingw-w64 default-jdk golang-go

# ---------------------------------------------------------------------------
# 6. Python3 + pip3
# ---------------------------------------------------------------------------
log_info "Python3 + pip3"
apt_install_if_missing git python3 python3-pip python3-dev curl

# ---------------------------------------------------------------------------
# 7. Fonts
# ---------------------------------------------------------------------------
log_info "Fonts"
apt_install_if_missing fonts-powerline fonts-hack fonts-font-awesome fonts-powerlinesymbols

# ---------------------------------------------------------------------------
# 8. VSCode
# ---------------------------------------------------------------------------
log_info "Visual Studio Code"
apt_add_keyring_asc "https://packages.microsoft.com/keys/microsoft.asc" /usr/share/keyrings/packages.microsoft.gpg
apt_add_source_list /etc/apt/sources.list.d/vscode.list \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main"
apt_install_if_missing code

# ---------------------------------------------------------------------------
# 9. Basic/system tools
# ---------------------------------------------------------------------------
log_info "Basic/system tools"
apt_install_if_missing gedit tree htop glances most ssh rdesktop freerdp-x11 ansible autojump acpi terminator

# ---------------------------------------------------------------------------
# 10. Pentest tool apt packages
# ---------------------------------------------------------------------------
# Note: seclists is intentionally NOT installed here via apt - the
# danielmiessler/SecLists git clone in section 15 is kept current and is the
# single source of truth for wordlists (avoids the old apt+git duplicate).
# snmpwalk/svwar dropped - not real standalone package names (they ship
# inside the snmp/sipvicious packages already listed below). khtmltopdf
# dropped as a non-existent duplicate of wkhtmltopdf.
log_info "Pentest tool apt packages"
apt_install_if_missing gobuster sslscan nikto joomscan wpscan smbmap enum4linux dnsrecon odat \
    ffuf nbtscan nmap onesixtyone oscanner smbclient snmp sipvicious tnscmd10g whatweb \
    smtp-user-enum nishang finalrecon feroxbuster impacket-scripts redis-tools wkhtmltopdf crunch

# Windows-Exploit-Suggester dependency
pip_install_if_missing xlrd

# ---------------------------------------------------------------------------
# 11. searchsploit
# ---------------------------------------------------------------------------
log_info "searchsploit"
apt_install_if_missing exploitdb
searchsploit -u

# ---------------------------------------------------------------------------
# 12. Python pip tools
# ---------------------------------------------------------------------------
log_info "Python pip tools"
pip_install_if_missing termcolor
pip_install_if_missing badchars
pip_install_if_missing requests
pip_install_if_missing dnspython
pip_install_if_missing psutil
pip_install_if_missing pwntools
# impacket (pip library, for scripting/imports) is distinct from the
# impacket-scripts apt package (standalone CLI tools) installed above -
# both are intentionally kept.
pip_install_if_missing impacket

# ---------------------------------------------------------------------------
# 13. CyberChef
# ---------------------------------------------------------------------------
log_info "CyberChef"
CYBERCHEF_DIR="/opt/CyberChef"
CYBERCHEF_VERSION="v9.32.3"
mkdir -p "$CYBERCHEF_DIR"
if [[ ! -f "$CYBERCHEF_DIR/CyberChef_${CYBERCHEF_VERSION}.zip" ]]; then
    wget -P "$CYBERCHEF_DIR" "https://github.com/gchq/CyberChef/releases/download/${CYBERCHEF_VERSION}/CyberChef_${CYBERCHEF_VERSION}.zip"
fi
if [[ ! -f "$CYBERCHEF_DIR/index.html" ]]; then
    unzip -o "$CYBERCHEF_DIR/CyberChef_${CYBERCHEF_VERSION}.zip" -d "$CYBERCHEF_DIR"
fi

# ---------------------------------------------------------------------------
# 14. Enumeration tools
# ---------------------------------------------------------------------------
log_info "AutoRecon - https://github.com/Tib3rius/AutoRecon"
pip_install_if_missing autorecon "git+https://github.com/Tib3rius/AutoRecon.git"

log_info "nmapAutomator - https://github.com/21y4d/nmapAutomator"
git_clone_or_update "https://github.com/21y4d/nmapAutomator.git" /opt/_Tools/nmapAutomator
sudo chmod +x /opt/_Tools/nmapAutomator/nmapAutomator.sh
sudo ln -sf /opt/_Tools/nmapAutomator/nmapAutomator.sh /usr/local/bin/nmapAutomator.sh

log_info "naabu - https://github.com/projectdiscovery/naabu"
git_clone_or_update "https://github.com/projectdiscovery/naabu.git" /opt/_Tools/naabu
(
    cd /opt/_Tools/naabu/v2/cmd/naabu
    go build
    sudo cp naabu /usr/local/bin/
)
naabu -version

# ---------------------------------------------------------------------------
# 15. Terminal customization
# ---------------------------------------------------------------------------
log_info "Terminal customization"
clone_terminal_customization

# ---------------------------------------------------------------------------
# 16. Priv-esc tool tree
# ---------------------------------------------------------------------------
log_info "Priv-esc file structure"
mkdir -p /opt/__PRIV_ESC/_WINDOWS/_EXECUTABLE
mkdir -p /opt/__PRIV_ESC/_WINDOWS/_POWERSHELL
mkdir -p /opt/__PRIV_ESC/_WINDOWS/_OTHER
mkdir -p /opt/__PRIV_ESC/_LINUX

log_info "Win/Lin priv-esc scripts"
git_clone_or_update "https://github.com/AlessandroZ/BeRoot.git" /opt/__PRIV_ESC/BeRoot-AlessandroZ

log_info "Linux priv-esc scripts"
PEASS_LATEST="https://github.com/carlospolop/PEASS-ng/releases/latest/download"
LINPEAS_DIR="/opt/__PRIV_ESC/_LINUX/0-Start_linPEAS-carlospolop"
mkdir -p "$LINPEAS_DIR"
[[ -f "$LINPEAS_DIR/linpeas.sh" ]] || wget -P "$LINPEAS_DIR" "$PEASS_LATEST/linpeas.sh"

git_clone_or_update "https://github.com/rebootuser/LinEnum.git" /opt/__PRIV_ESC/_LINUX/1_LinEnum-rebootuser
git_clone_or_update "https://github.com/redcode-labs/Citadel.git" /opt/__PRIV_ESC/_LINUX/Citadel-redcode-labs
git_clone_or_update "https://github.com/redcode-labs/Bashark" /opt/__PRIV_ESC/_LINUX/Bashark-redcode-labs
git_clone_or_update "https://github.com/mzet-/linux-exploit-suggester.git" /opt/__PRIV_ESC/_LINUX/2_linux-exploit-suggester-mzet-
git_clone_or_update "https://github.com/sleventyeleven/linuxprivchecker.git" /opt/__PRIV_ESC/_LINUX/linuxprivchecker-Py-sleventyeleven
git_clone_or_update "https://github.com/diego-treitos/linux-smart-enumeration.git" /opt/__PRIV_ESC/_LINUX/linux-smart-enumeration-diego-treitos
git_clone_or_update "https://github.com/ohpe/juicy-potato.git" /opt/__PRIV_ESC/_LINUX/juicy-potato-ohpe

log_info "Windows priv-esc scripts"
WINPEAS_DIR="/opt/__PRIV_ESC/_WINDOWS/0-Start_winPEAS-carlospolop"
mkdir -p "$WINPEAS_DIR"
[[ -f "$WINPEAS_DIR/winPEAS.bat" ]]    || wget -P "$WINPEAS_DIR" "$PEASS_LATEST/winPEAS.bat"
[[ -f "$WINPEAS_DIR/winPEASx64.exe" ]] || wget -P "$WINPEAS_DIR" "$PEASS_LATEST/winPEASx64.exe"
[[ -f "$WINPEAS_DIR/winPEASx86.exe" ]] || wget -P "$WINPEAS_DIR" "$PEASS_LATEST/winPEASx86.exe"

git_clone_or_update "https://github.com/AonCyberLabs/Windows-Exploit-Suggester.git" /opt/__PRIV_ESC/_WINDOWS/_OTHER/Windows-Exploit-Suggester-AonCyberLabs
WES_NOTES="/opt/__PRIV_ESC/_WINDOWS/_OTHER/howToUpdateWindowsExploiter.txt"
if [[ ! -f "$WES_NOTES" ]]; then
    cat > "$WES_NOTES" <<-'EOF'
	./windows-exploit-suggester.py --update
	./windows-exploit-suggester.py --database 2014-06-06-mssb.xlsx --systeminfo win7sp1-systeminfo.txt
	EOF
fi

git_clone_or_update "https://github.com/pentestmonkey/windows-privesc-check.git" /opt/__PRIV_ESC/_WINDOWS/_OTHER/windows-privesc-check-pentestmonkey
git_clone_or_update "https://github.com/absolomb/WindowsEnum.git" /opt/__PRIV_ESC/_WINDOWS/2_WindowsEnum-absolomb
git_clone_or_update "https://github.com/M4ximuss/Powerless.git" /opt/__PRIV_ESC/_WINDOWS/_OTHER/Powerless-M4ximuss
git_clone_or_update "https://github.com/bitsadmin/wesng.git" /opt/__PRIV_ESC/_WINDOWS/_OTHER/wesng-bitsadmin
git_clone_or_update "https://github.com/rasta-mouse/Sherlock.git" /opt/__PRIV_ESC/_WINDOWS/_POWERSHELL/Sherlock-rasta-mouse
git_clone_or_update "https://github.com/rasta-mouse/Watson.git" /opt/__PRIV_ESC/_WINDOWS/_EXECUTABLE/Watson-rasta-mouse
git_clone_or_update "https://github.com/abatchy17/WindowsExploits.git" /opt/__PRIV_ESC/_WINDOWS/_OTHER/WindowsExploits-abatchy17
git_clone_or_update "https://github.com/7Ragnarok7/Windows-Exploit-Suggester-2.git" /opt/__PRIV_ESC/_WINDOWS/1_Windows-Exploit-Suggester-2-7Ragnarok7
# Full repo clone - git can't clone a GitHub /tree/ subpath URL directly;
# only the Privesc/ subfolder is typically used, but sparse-checkout isn't
# worth the added complexity here.
git_clone_or_update "https://github.com/PowerShellMafia/PowerSploit.git" /opt/__PRIV_ESC/_WINDOWS/_POWERSHELL/PowerSploit-PowerShellMafia
git_clone_or_update "https://github.com/frizb/Windows-Privilege-Escalation" /opt/__PRIV_ESC/_WINDOWS/_OTHER/Windows-Privilege-Escalation-frizb
git_clone_or_update "https://github.com/SecWiki/windows-kernel-exploits" /opt/__PRIV_ESC/_WINDOWS/_OTHER/windows-kernel-exploits-SecWiki
git_clone_or_update "https://github.com/GhostPack/SharpUp" /opt/__PRIV_ESC/_WINDOWS/_EXECUTABLE/windows-SharpUp-GhostPack
git_clone_or_update "https://github.com/GhostPack/Seatbelt" /opt/__PRIV_ESC/_WINDOWS/_EXECUTABLE/Seatbelti-GhostPack
git_clone_or_update "https://github.com/411Hall/JAWS" /opt/__PRIV_ESC/_WINDOWS/_POWERSHELL/JAWS-411Hall

# ---------------------------------------------------------------------------
# 17. Payload/recon scripts
# ---------------------------------------------------------------------------
log_info "Payload/recon scripts"
mkdir -p /opt/_Payload_Scripts
git_clone_or_update "https://github.com/swisskyrepo/PayloadsAllTheThings.git" /opt/_Payload_Scripts/PayloadsAllTheThings-swisskyrepo
git_clone_or_update "https://github.com/g0tmi1k/msfpc" /opt/_Payload_Scripts/MSFvenom-Payload-Creator-g0tmi1k
git_clone_or_update "https://github.com/ShutdownRepo/shellerator.git" /opt/_Payload_Scripts/shellerator-ShutdownRepo
git_clone_or_update "https://github.com/Gr1mmie/sumrecon.git" /opt/_Payload_Scripts/sumrecon-Gr1mmie

SECLISTS_DIR="/opt/_Payload_Scripts/SecLists-danielmiessler"
git_clone_or_update "https://github.com/danielmiessler/SecLists" "$SECLISTS_DIR"

pip_install_if_missing pwncat "git+https://github.com/calebstewart/pwncat.git"

log_info "gimmeSH"
git_clone_or_update "https://github.com/A3h1nt/gimmeSH" /opt/_Tools/gimmeSH
sudo chmod +x /opt/_Tools/gimmeSH/gimmeSH.sh
sudo ln -sf /opt/_Tools/gimmeSH/gimmeSH.sh /usr/local/bin/gimmeSH.sh

log_info "assetfinder - https://github.com/tomnomnom/assetfinder"
go install github.com/tomnomnom/assetfinder@latest

# ---------------------------------------------------------------------------
# 18. Mega dir-busting wordlist
# ---------------------------------------------------------------------------
MEGA_DIRBUSTER="/opt/_Payload_Scripts/mega-dirbuster.txt"
if [[ ! -f "$MEGA_DIRBUSTER" ]]; then
    log_info "Building mega-dirbuster.txt"
    sort -u "$SECLISTS_DIR"/Discovery/Web-Content/{big.txt,common.txt,directory-list-2.3*,raft-large-directories.txt,raft-large-files.txt,raft-medium-directories.txt,raft-medium-files.txt,raft-small-directories.txt,RobotsDisallowed-Top1000.txt} \
        > "$MEGA_DIRBUSTER"
fi

# ---------------------------------------------------------------------------
# 19. rockyou.txt UTF-8 fix
# ---------------------------------------------------------------------------
ROCKYOU_DIR="$SECLISTS_DIR/Passwords/Leaked-Databases"
if [[ ! -f "$ROCKYOU_DIR/rockyou.txt" ]]; then
    log_info "Extracting rockyou.txt"
    tar -xzvf "$ROCKYOU_DIR/rockyou.txt.tar.gz" -C "$ROCKYOU_DIR"
fi
if [[ ! -f "$ROCKYOU_DIR/rockyou-UTF8.txt" ]]; then
    log_info "Converting rockyou.txt to UTF-8"
    iconv -f ISO-8859-1 -t UTF-8//TRANSLIT "$ROCKYOU_DIR/rockyou.txt" -o "$ROCKYOU_DIR/rockyou-UTF8.txt"
fi

# ---------------------------------------------------------------------------
# 20. ~/HACKING working directory
# ---------------------------------------------------------------------------
install -d -m 2775 "$HOME/HACKING"

# ---------------------------------------------------------------------------
# 21. Sudo lecture / pwfeedback
# ---------------------------------------------------------------------------
add_sudo_lecture_config "$REPO_ROOT"

# ---------------------------------------------------------------------------
# 22. Final update pass
# ---------------------------------------------------------------------------
log_info "Final update pass"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y

# ---------------------------------------------------------------------------
# 23. Reboot prompt
# ---------------------------------------------------------------------------
confirm_reboot_prompt
