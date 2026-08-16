#!/usr/bin/env bash
# Kali_Setup.sh - provisions a fresh Kali Linux box for pentest work: recon
# and enumeration tools, a privilege-escalation script tree for both Linux
# and Windows targets, and payload/recon scripts. Does NOT install desktop
# productivity apps like Discord or Slack, that's what Gnome_Setup.sh and
# Fedora_Setup.sh are for, this script is purely about the tooling.
#
# Why a script instead of a manual checklist: setting up a pentest box by
# hand means remembering dozens of tools, their install methods, and the
# handful of manual fixes each one needs (wordlist encoding, build paths
# that aren't the repo root, etc). Miss one and you find out mid-engagement.
# This script is that checklist, automated and safe to re-run, so "set up a
# new Kali box" is one command and a cup of coffee instead of a half-day of
# chasing down tools one at a time.
#
# A few design decisions worth understanding before you edit this file:
#   - Idempotent: every install/config/clone step below checks "is this
#     already done?" before doing anything. That means you can re-run this
#     script any time, after a failure partway through, to pick up a new
#     tool someone added later, to catch a machine up that's fallen behind,
#     and it will only do the work that's still actually needed instead of
#     erroring out on things that already exist or duplicating clones.
#   - Self-locating: SCRIPT_DIR/REPO_ROOT below figure out where this repo
#     actually lives on disk at runtime (see the comment above them), so
#     cloning this repo to a different path, or running the script from a
#     different working directory, never breaks the `source lib/common.sh`
#     line further down.
#   - Shared helpers live in lib/common.sh, not in this file. Logging,
#     git clone/update, the shared /opt setup, sudo config, the reboot
#     prompt, all of that is defined once there and sourced here. This
#     script also defines its own apt/pip helpers just below, specific to
#     Kali's much longer tool list, that Gnome_Setup.sh and Fedora_Setup.sh
#     don't need.
#   - Shell/terminal customization (oh-my-zsh, zsh plugins, powerlevel10k,
#     .zshrc) is fully delegated to the Terminal-Customization repo cloned
#     further down, this script does not touch zsh, your shell config, or
#     any dotfiles at all. That's a deliberate separation: tooling and
#     shell config change on different schedules and shouldn't be coupled.
#
# Usage: ./Kali_Setup.sh
# Run as your normal user, NOT with sudo, see the EUID check just below for
# why that matters. Individual steps call sudo internally, only for the
# specific commands that actually need root, package installs, writing
# under /etc, and so on.

set -euo pipefail
# -e: stop immediately on any command that fails, instead of plowing ahead
#     with a half-finished tool install. Especially important here, this
#     script chains a lot of clone-then-build steps where a failure partway
#     through (a bad naabu build, say) shouldn't be masked by later steps
#     appearing to "succeed".
# -u: treat referencing an unset variable as an error, catches typos in
#     variable names (there are a lot of them in this file, PEASS_RELEASE,
#     SECLISTS_DIR, and friends) before they cause a confusing failure
#     somewhere downstream instead of right where the typo is.
# -o pipefail: a pipeline (a | b) fails if ANY stage fails, not just the
#     last one, so a failure early in a pipe can't get silently swallowed.

if [[ $EUID -eq 0 ]]; then
    # Running this whole script as root would mean every "user-scoped" step
    # below (pip installs without sudo not shown here since they do use
    # sudo, git clones under /opt and $HOME, the ~/HACKING and ~/Dev
    # folders, go installs) ends up owned by root instead of you, which is
    # exactly the kind of mess that's annoying to untangle later. Individual
    # commands below call sudo themselves for the specific things that
    # actually need root, so there's no reason to run the whole script
    # elevated.
    echo "[x] Run this script as your normal user, not with sudo. It sudos internally as needed." >&2
    exit 1
fi

# Resolve this script's real directory and the repo root above it, using
# BASH_SOURCE (not $0, which can be wrong when a script is sourced) so this
# works no matter where the repo is cloned to or what directory you run it
# from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$REPO_ROOT/lib/common.sh"

# --- apt-specific idempotency helpers (mirrors Gnome_Setup.sh) ------------
# These, plus pip_install_if_missing just below, are how every install in
# this script stays idempotent. Read through them once, everything past
# this point is just these five functions called over and over with
# different arguments.

# Installs whichever of the given packages aren't already installed,
# skipping the ones dpkg already knows about. $@ = package names.
# Batches everything into a single apt-get install call instead of one call
# per package: apt resolves shared dependencies once instead of repeatedly,
# and you get one transaction instead of a dozen. With the size of the
# pentest tool list below, this matters more here than anywhere else in
# this repo.
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

# Downloads an already-binary (not ascii-armored) gpg key straight to a
# keyring file. $1 = key URL, $2 = destination keyring path.
# Not apt-key: apt-key is deprecated and trusted every key it held for
# every repo on the system, one bad key could vouch for packages from any
# repo. Each vendor's key living in its own file, referenced by that one
# repo's signed-by= line, means a key only ever vouches for its own repo.
apt_add_keyring_bin() {
    local key_url="$1" keyring="$2"
    if [[ ! -f "$keyring" ]]; then
        log_info "Adding keyring: $keyring"
        sudo curl -fsSLo "$keyring" "$key_url"
    fi
}

# Same idea as apt_add_keyring_bin, but for vendors that publish their key
# ascii-armored instead of already binary, `gpg --dearmor` converts it
# before it's written to the keyring file. $1 = key URL, $2 = destination
# keyring path.
apt_add_keyring_asc() {
    local key_url="$1" keyring="$2"
    if [[ ! -f "$keyring" ]]; then
        log_info "Adding keyring: $keyring"
        curl -fsSL "$key_url" | gpg --dearmor | sudo tee "$keyring" >/dev/null
    fi
}

# Writes a one-line apt source file if it doesn't already contain the given
# deb line, then refreshes apt so the new repo is usable right away.
# $1 = sources.list.d file, $2 = deb line (normally including a
# signed-by=<keyring path> pointing at whatever apt_add_keyring_* wrote).
apt_add_source_list() {
    local list_file="$1" deb_line="$2"
    if [[ ! -f "$list_file" ]] || ! grep -qF "$deb_line" "$list_file"; then
        log_info "Adding apt source: $list_file"
        echo "$deb_line" | sudo tee "$list_file" >/dev/null
        sudo apt-get update
    fi
}

# Installs a pip package if it isn't already present. Checking via `pip
# show` rather than trying to import the module means this works even for
# packages whose importable name differs from their pypi name, and doesn't
# require guessing what the module is called. $1 = package name to check,
# $2 = install spec (pypi name, or git+URL / package name if different, see
# autorecon and pwncat below for examples where the two aren't the same).
pip_install_if_missing() {
    local pkg="$1" install_spec="${2:-$1}"
    if python3 -m pip show "$pkg" &>/dev/null; then
        log_info "$pkg already installed (pip), skipping"
    else
        log_info "Installing (pip): $pkg"
        sudo python3 -m pip install "$install_spec"
    fi
}

# Fails loudly if a downloaded file's sha256 doesn't match what's expected.
# $1 = file path, $2 = expected sha256. Used for the linPEAS/winPEAS
# binaries below, which PEASS-ng doesn't publish a vendor checksum for at
# all (checked its GitHub releases directly, no .sha256/SHASUMS asset
# exists), so these are hashes this repo computed and commits to itself at
# pin time, not vendor-attested ones. Still worth having: it catches a
# corrupted download or a byte-for-byte change in the pinned release
# (accidental or otherwise) instead of silently running whatever came back.
verify_sha256_or_die() {
    local file="$1" expected="$2" actual
    actual="$(sha256sum "$file" | awk '{print $1}')"
    if [[ "$actual" != "$expected" ]]; then
        log_error "$file: sha256 mismatch (expected $expected, got $actual), aborting rather than using an unverified file"
        rm -f "$file"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# 1. System update
# ---------------------------------------------------------------------------
# Always do this first. Updating and upgrading before installing anything
# new means every step below is working against current package metadata
# instead of fighting a stale cache. full-upgrade (not a plain upgrade) is
# used deliberately here, Kali's rolling-release model occasionally needs
# to remove or replace packages to resolve a dependency change, which a
# plain `apt upgrade` refuses to do and would just leave half-upgraded.
log_info "System update"
sudo apt-get update
sudo apt-get full-upgrade -y
sudo apt-get autoremove -y

# ---------------------------------------------------------------------------
# 2. Shared /opt setup
# ---------------------------------------------------------------------------
# Sets /opt group-writable so the unprivileged mkdir -p/git clone calls in
# later sections (CyberChef, priv-esc tree, payload scripts) don't need sudo.
log_info "Preparing /opt for tool clones"
ensure_opt_dir

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
# Not just "nice to have", several tools later in this script are built
# from source rather than installed as packages (naabu and assetfinder need
# Go, PimpMyKali-era tooling needed a JDK for some Java-based tools), and
# libffi-dev/libssl-dev are common build requirements for Python packages
# with native extensions (pwntools and impacket below both lean on them).
# gcc-mingw-w64 specifically is for cross-compiling Windows payloads/binaries
# from this Linux box, a very pentest-specific need the other two setup
# scripts don't have any reason to carry.
log_info "Build/dev toolchain"
apt_install_if_missing build-essential manpages-dev libpcap-dev libffi-dev libssl-dev gcc-mingw-w64 default-jdk golang-go

# ---------------------------------------------------------------------------
# 6. Python3 + pip3
# ---------------------------------------------------------------------------
# A huge amount of the pentest tooling in this script (Python pip tools
# section, AutoRecon, pwncat, and more) is Python-based, so this needs to
# be solid early. python3-dev specifically (headers, not just the
# interpreter) is what lets pip build native-extension packages like
# pwntools from source instead of failing partway through.
log_info "Python3 + pip3"
apt_install_if_missing git python3 python3-pip python3-dev curl

# ---------------------------------------------------------------------------
# 7. Fonts
# ---------------------------------------------------------------------------
# Purely cosmetic, but worth having before Terminal-Customization sets up a
# themed prompt later: powerline-style prompts and icon fonts render as
# broken boxes without glyph fonts like these already present on the system.
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
# Not pentest-specific, just the everyday utilities a box like this needs:
# better process/disk visibility than the bare coreutils give you, a
# friendlier pager, remote-access clients (ssh, rdesktop, freerdp-x11) for
# jumping onto other boxes mid-engagement, ansible/autojump/acpi for
# general convenience, and two terminal emulators.
log_info "Basic/system tools"
apt_install_if_missing gedit tree htop glances most ssh rdesktop freerdp-x11 ansible autojump acpi terminator

# Ghostty doesn't publish a .deb or an apt repo, and despite reserving a
# Flathub app id (com.mitchellh.ghostty), it was never actually published
# there either, confirmed directly: that app id 404s on Flathub and its
# search returns nothing. Every remaining Linux option ghostty.org itself
# lists is a third-party "Community Binary" it explicitly warns carries
# tampering risk, "not official packages... implicitly accept the risk of a
# third party", except Snap: ghostty.org states the Snap build itself runs
# through Ghostty's own CI, not a stranger's. That's the one used here.
log_info "Ghostty (no apt package, no real Flatpak, using Snap)"
snap_install_if_missing ghostty ghostty
configure_ghostty_theme

# ---------------------------------------------------------------------------
# 10. Pentest tool apt packages
# ---------------------------------------------------------------------------
# Note: seclists is intentionally NOT installed here via apt - the
# danielmiessler/SecLists git clone in the Payload/recon scripts section
# below is kept current and is the single source of truth for wordlists
# (avoids the old apt+git duplicate). Described by name, not section number,
# so a future renumbering can't quietly make this comment wrong again.
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
# CyberChef ships as a static, offline-capable single-page app, not a
# package or a git repo, so a version-pinned release zip is the intended
# way to install it, downloaded once and unzipped in place.
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
# Where the "Pentest tool apt packages" section above installed individual
# scanning tools, these three are automation wrappers around them, they
# chain nmap and friends together into a full recon workflow instead of
# you running each tool by hand. Installed via pip/git clone instead of
# apt because none of them ship an apt package.
log_info "AutoRecon - https://github.com/Tib3rius/AutoRecon"
pip_install_if_missing autorecon "git+https://github.com/Tib3rius/AutoRecon.git"

log_info "nmapAutomator - https://github.com/21y4d/nmapAutomator"
git_clone_or_update "https://github.com/21y4d/nmapAutomator.git" /opt/_Tools/nmapAutomator
sudo chmod +x /opt/_Tools/nmapAutomator/nmapAutomator.sh
sudo ln -sf /opt/_Tools/nmapAutomator/nmapAutomator.sh /usr/local/bin/nmapAutomator.sh

log_info "naabu - https://github.com/projectdiscovery/naabu"
git_clone_or_update "https://github.com/projectdiscovery/naabu.git" /opt/_Tools/naabu
# naabu's main package lives under v2/cmd/naabu in its repo, not the repo
# root, so `go install .../naabu@latest` won't find it. Building manually
# from that subpath and copying the binary out is the reliable path here.
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
# Folders are created up front, split by OS and then by script type
# (executable/PowerShell/other), so every git_clone_or_update call below has
# a predictable, already-existing home to land in instead of dumping
# everything in one flat directory.
mkdir -p /opt/__PRIV_ESC/_WINDOWS/_EXECUTABLE
mkdir -p /opt/__PRIV_ESC/_WINDOWS/_POWERSHELL
mkdir -p /opt/__PRIV_ESC/_WINDOWS/_OTHER
mkdir -p /opt/__PRIV_ESC/_LINUX

log_info "Win/Lin priv-esc scripts"
git_clone_or_update "https://github.com/AlessandroZ/BeRoot.git" /opt/__PRIV_ESC/BeRoot-AlessandroZ

log_info "Linux priv-esc scripts"
# Pinned to a specific PEASS-ng release tag, same pattern as CyberChef
# above, instead of /releases/latest/download, which would silently pull in
# whatever's newest on every re-run with nothing to review first. PEASS-ng
# doesn't publish a checksum file in its releases (checked directly, no
# .sha256/SHASUMS asset exists), so verify_sha256_or_die above checks
# against hashes this repo computed itself at pin time, not a vendor one.
PEASS_TAG="20260814-55a4f278"
PEASS_RELEASE="https://github.com/carlospolop/PEASS-ng/releases/download/${PEASS_TAG}"
LINPEAS_DIR="/opt/__PRIV_ESC/_LINUX/0-Start_linPEAS-carlospolop"
mkdir -p "$LINPEAS_DIR"
if [[ ! -f "$LINPEAS_DIR/linpeas.sh" ]]; then
    wget -P "$LINPEAS_DIR" "$PEASS_RELEASE/linpeas.sh"
    verify_sha256_or_die "$LINPEAS_DIR/linpeas.sh" "06f94651d916b4f0faca4433517e01af50f8ae97f18c9e65e3148b5032445f57"
fi

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
if [[ ! -f "$WINPEAS_DIR/winPEAS.bat" ]]; then
    wget -P "$WINPEAS_DIR" "$PEASS_RELEASE/winPEAS.bat"
    verify_sha256_or_die "$WINPEAS_DIR/winPEAS.bat" "11e4ea92ce2465f3d30c5a56fd4aeba2aecaf4d1c2670ac42bd61c4db2becf87"
fi
if [[ ! -f "$WINPEAS_DIR/winPEASx64.exe" ]]; then
    wget -P "$WINPEAS_DIR" "$PEASS_RELEASE/winPEASx64.exe"
    verify_sha256_or_die "$WINPEAS_DIR/winPEASx64.exe" "5077beb3ac63049ff67c436b26f781a2bd08c7d7b182308ac868bef135b76840"
fi
if [[ ! -f "$WINPEAS_DIR/winPEASx86.exe" ]]; then
    wget -P "$WINPEAS_DIR" "$PEASS_RELEASE/winPEASx86.exe"
    verify_sha256_or_die "$WINPEAS_DIR/winPEASx86.exe" "ba1d155fe2eb8243b45e9c1f5c13c482697f196e3a012e81dbe021f780f49dc1"
fi

git_clone_or_update "https://github.com/AonCyberLabs/Windows-Exploit-Suggester.git" /opt/__PRIV_ESC/_WINDOWS/_OTHER/Windows-Exploit-Suggester-AonCyberLabs
WES_NOTES="/opt/__PRIV_ESC/_WINDOWS/_OTHER/howToUpdateWindowsExploiter.txt"
# Windows-Exploit-Suggester needs its database updated before it's useful
# and takes a systeminfo dump as input, neither is obvious from the tool
# itself, so the two commands you actually need get written down here.
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
    # Merges the highest-value SecLists web-content wordlists into one
    # sorted, deduplicated file, so dir-busting tools only need one -w
    # target instead of picking a single list and hoping it's the right one.
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
    # rockyou.txt ships Latin-1 (ISO-8859-1) encoded, which breaks tools
    # that assume UTF-8 input. Keeping a converted copy alongside the
    # original avoids surprising failures without touching the source file.
    log_info "Converting rockyou.txt to UTF-8"
    iconv -f ISO-8859-1 -t UTF-8//TRANSLIT "$ROCKYOU_DIR/rockyou.txt" -o "$ROCKYOU_DIR/rockyou-UTF8.txt"
fi

# ---------------------------------------------------------------------------
# 20. ~/HACKING working directory
# ---------------------------------------------------------------------------
# Scratch space for whatever engagement you're currently working on, loot,
# scan output, notes, anything. 2775 (group-writable, setgid) matches the
# same reasoning as /opt in ensure_opt_dir: usable without needing sudo for
# every file, without being world-writable either.
install -d -m 2775 "$HOME/HACKING"

# ---------------------------------------------------------------------------
# 21. ~/Dev folder
# ---------------------------------------------------------------------------
# A blank slate for your own scripts and projects that aren't tied to a
# specific engagement, deliberately separate from both ~/HACKING (scratch
# space for engagement work) and /opt (reserved for the tool installs this
# script itself manages), so nothing you create here is ever at risk of
# being touched by a future re-run.
log_info "Dev folder"
mkdir -p "$HOME/Dev"

# ---------------------------------------------------------------------------
# 22. Sudo lecture / pwfeedback
# ---------------------------------------------------------------------------
# See add_sudo_lecture_config in lib/common.sh for what this actually
# configures and why it's done as a sudoers.d drop-in. Worth having on a
# box like this in particular, you'll be typing your password after nearly
# every other command.
add_sudo_lecture_config "$REPO_ROOT"

# ---------------------------------------------------------------------------
# 23. Final update pass
# ---------------------------------------------------------------------------
# Runs again at the end, not just at the start, because several steps above
# added new apt repos (Brave, VS Code). Those repos' own packages wouldn't
# be picked up by the update at the top of this script, catching it now
# means the very first `apt upgrade` you run by hand after this finishes
# isn't a surprisingly large one.
log_info "Final update pass"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y

# ---------------------------------------------------------------------------
# 24. Reboot prompt
# ---------------------------------------------------------------------------
# See confirm_reboot_prompt in lib/common.sh for why a reboot is actually
# worth offering here rather than just ending the script.
confirm_reboot_prompt
