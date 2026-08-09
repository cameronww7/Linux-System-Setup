#!/usr/bin/env bash
# Gnome_Setup.sh - provisions a Debian/Ubuntu-family GNOME desktop.
#
# Usage: ./Gnome_Setup.sh
# Run as a normal user (not with sudo) - individual privileged steps sudo
# internally. Safe to re-run: every step checks whether it's already done
# before installing/adding anything again.

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "[x] Run this script as your normal user, not with sudo. It sudos internally as needed." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$REPO_ROOT/lib/common.sh"

# --- apt-specific idempotency helpers -------------------------------------

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

# $1 = ascii-armored key URL, $2 = destination keyring path
apt_add_keyring_asc() {
    local key_url="$1" keyring="$2"
    if [[ ! -f "$keyring" ]]; then
        log_info "Adding keyring: $keyring"
        curl -fsSL "$key_url" | gpg --dearmor | sudo tee "$keyring" >/dev/null
    fi
}

# $1 = already-binary gpg key URL, $2 = destination keyring path
apt_add_keyring_bin() {
    local key_url="$1" keyring="$2"
    if [[ ! -f "$keyring" ]]; then
        log_info "Adding keyring: $keyring"
        sudo curl -fsSLo "$keyring" "$key_url"
    fi
}

# $1 = sources.list.d file, $2 = deb line
apt_add_source_list() {
    local list_file="$1" deb_line="$2"
    if [[ ! -f "$list_file" ]] || ! grep -qF "$deb_line" "$list_file"; then
        log_info "Adding apt source: $list_file"
        echo "$deb_line" | sudo tee "$list_file" >/dev/null
        sudo apt-get update
    fi
}

# $1 = dpkg package name to check, $2 = .deb download URL
apt_install_deb_url_if_missing() {
    local pkg="$1" url="$2" tmp_deb
    if dpkg -s "$pkg" &>/dev/null; then
        log_info "$pkg already installed, skipping"
        return
    fi
    tmp_deb="$(mktemp --suffix=.deb)"
    log_info "Downloading $pkg from $url"
    curl -fsSLo "$tmp_deb" "$url"
    sudo apt-get install -y "$tmp_deb"
    rm -f "$tmp_deb"
}

# ---------------------------------------------------------------------------
# 1. System update
# ---------------------------------------------------------------------------
log_info "System update"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y

# ---------------------------------------------------------------------------
# 2. Base dev tools
# ---------------------------------------------------------------------------
log_info "Base dev tools"
apt_install_if_missing curl git perl python3 python3-pip build-essential manpages-dev libpcap-dev

# ---------------------------------------------------------------------------
# 3. Browsers
# ---------------------------------------------------------------------------
log_info "Brave browser"
apt_add_keyring_bin "https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg" /usr/share/keyrings/brave-browser-archive-keyring.gpg
apt_add_source_list /etc/apt/sources.list.d/brave-browser-release.list \
    "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"
apt_install_if_missing brave-browser

# ---------------------------------------------------------------------------
# 4. Productivity apps
# ---------------------------------------------------------------------------
log_info "Discord"
apt_install_deb_url_if_missing discord "https://discord.com/api/download?platform=linux&format=deb"

log_info "Slack"
apt_add_keyring_asc "https://packagecloud.io/slacktechnologies/slack/gpgkey" /usr/share/keyrings/slack-archive-keyring.gpg
apt_add_source_list /etc/apt/sources.list.d/slack.list \
    "deb [signed-by=/usr/share/keyrings/slack-archive-keyring.gpg] https://packagecloud.io/slacktechnologies/slack/debian/ jessie main"
apt_install_if_missing slack-desktop

log_info "Zoom"
apt_install_deb_url_if_missing zoom "https://zoom.us/client/latest/zoom_amd64.deb"

log_info "Visual Studio Code"
apt_add_keyring_asc "https://packages.microsoft.com/keys/microsoft.asc" /usr/share/keyrings/packages.microsoft.gpg
apt_add_source_list /etc/apt/sources.list.d/vscode.list \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main"
apt_install_if_missing code

log_info "ProtonVPN"
if [[ ! -f /etc/apt/sources.list.d/protonvpn-stable.list ]]; then
    proton_deb="$(mktemp --suffix=.deb)"
    curl -fsSLo "$proton_deb" "https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.3_all.deb"
    sudo apt-get install -y "$proton_deb"
    sudo apt-get update
    rm -f "$proton_deb"
fi
apt_install_if_missing proton-vpn-gnome-desktop

log_info "Spotify"
apt_add_keyring_asc "https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg" /usr/share/keyrings/spotify.gpg
apt_add_source_list /etc/apt/sources.list.d/spotify.list \
    "deb [signed-by=/usr/share/keyrings/spotify.gpg] http://repository.spotify.com stable non-free"
apt_install_if_missing spotify-client

log_info "GitHub Desktop (community shiftkey/desktop repo, not GitHub-official)"
apt_add_keyring_asc "https://apt.packages.shiftkey.dev/gpg.key" /usr/share/keyrings/shiftkey-packages.gpg
apt_add_source_list /etc/apt/sources.list.d/shiftkey-packages.list \
    "deb [signed-by=/usr/share/keyrings/shiftkey-packages.gpg arch=amd64] https://apt.packages.shiftkey.dev/ubuntu/ any main"
apt_install_if_missing github-desktop

log_info "Signal"
apt_add_keyring_asc "https://updates.signal.org/desktop/apt/keys.asc" /usr/share/keyrings/signal-desktop-keyring.gpg
apt_add_source_list /etc/apt/sources.list.d/signal-xenial.list \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main"
apt_install_if_missing signal-desktop

log_info "Claude Code"
apt_install_if_missing nodejs npm
if ! command_exists claude; then
    sudo npm install -g @anthropic-ai/claude-code
else
    log_info "Claude Code already installed (run 'sudo npm update -g @anthropic-ai/claude-code' to update)"
fi

# ---------------------------------------------------------------------------
# 5. Quality-of-life tools
# ---------------------------------------------------------------------------
log_info "Quality-of-life tools"
apt_install_if_missing gedit tree htop glances most libreoffice

# ---------------------------------------------------------------------------
# 6. Terminal customization
# ---------------------------------------------------------------------------
log_info "Terminal customization"
clone_terminal_customization

# ---------------------------------------------------------------------------
# 7. Sudo lecture / pwfeedback
# ---------------------------------------------------------------------------
add_sudo_lecture_config "$REPO_ROOT"

# ---------------------------------------------------------------------------
# 8. Final update pass
# ---------------------------------------------------------------------------
log_info "Final update pass"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y

# ---------------------------------------------------------------------------
# 9. Reboot prompt
# ---------------------------------------------------------------------------
confirm_reboot_prompt
