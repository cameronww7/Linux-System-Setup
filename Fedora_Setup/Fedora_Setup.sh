#!/usr/bin/env bash
# Fedora_Setup.sh - provisions a Fedora (GNOME) desktop. Mirrors Gnome_Setup.sh
# section-for-section, using dnf/rpm instead of apt/deb.
#
# Usage: ./Fedora_Setup.sh
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

# --- dnf-specific idempotency helpers --------------------------------------

dnf_install_if_missing() {
    local missing=()
    for pkg in "$@"; do
        rpm -q "$pkg" &>/dev/null || missing+=("$pkg")
    done
    if ((${#missing[@]})); then
        log_info "Installing: ${missing[*]}"
        sudo dnf install -y "${missing[@]}"
    else
        log_info "Already installed, skipping: $*"
    fi
}

dnf_group_install_if_missing() {
    local group="$1"
    if dnf group list --installed 2>/dev/null | grep -qF "$group"; then
        log_info "Group already installed, skipping: $group"
    else
        log_info "Installing group: $group"
        sudo dnf groupinstall -y "$group"
    fi
}

# $1 = package name to check, $2 = rpm URL (dnf downloads and resolves deps itself)
dnf_install_rpm_url_if_missing() {
    local pkg="$1" url="$2"
    if rpm -q "$pkg" &>/dev/null; then
        log_info "$pkg already installed, skipping"
        return
    fi
    log_info "Installing $pkg from $url"
    sudo dnf install -y "$url"
}

# $1 = /etc/yum.repos.d/*.repo path, $2 = repo file contents, $3 = gpg key URL to import
dnf_write_repo_if_absent() {
    local repo_file="$1" content="$2" gpgkey_url="$3"
    if [[ -f "$repo_file" ]]; then
        log_info "Repo already present: $repo_file"
        return
    fi
    log_info "Adding dnf repo file: $repo_file"
    sudo rpm --import "$gpgkey_url"
    echo "$content" | sudo tee "$repo_file" >/dev/null
    sudo dnf makecache
}

ensure_flatpak_flathub() {
    dnf_install_if_missing flatpak
    if ! flatpak remote-list 2>/dev/null | grep -q '^flathub'; then
        log_info "Adding Flathub remote"
        sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
}

# $1 = flatpak app id
flatpak_install_if_missing() {
    local app_id="$1"
    ensure_flatpak_flathub
    if flatpak list --app 2>/dev/null | grep -q "$app_id"; then
        log_info "$app_id already installed (flatpak), skipping"
    else
        log_info "Installing $app_id via flatpak"
        sudo flatpak install -y flathub "$app_id"
    fi
}

# ---------------------------------------------------------------------------
# 1. System update
# ---------------------------------------------------------------------------
log_info "System update"
sudo dnf upgrade --refresh -y
sudo dnf autoremove -y

# ---------------------------------------------------------------------------
# 2. Base dev tools
# ---------------------------------------------------------------------------
log_info "Base dev tools"
dnf_install_if_missing curl git perl python3 python3-pip man-pages libpcap-devel
dnf_group_install_if_missing "Development Tools"

# ---------------------------------------------------------------------------
# 3. Browsers
# ---------------------------------------------------------------------------
log_info "Brave browser"
dnf_write_repo_if_absent /etc/yum.repos.d/brave-browser.repo \
"[brave-browser]
name=Brave Browser
baseurl=https://brave-browser-rpm-release.s3.brave.com/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc" \
"https://brave-browser-rpm-release.s3.brave.com/brave-core.asc"
dnf_install_if_missing brave-browser

# ---------------------------------------------------------------------------
# 4. Productivity apps
# ---------------------------------------------------------------------------
log_info "Discord (no official rpm, using Flatpak)"
flatpak_install_if_missing com.discordapp.Discord

log_info "Slack (no stable versioned rpm URL from Slack, using Flatpak)"
flatpak_install_if_missing com.slack.Slack

log_info "Zoom"
dnf_install_rpm_url_if_missing zoom "https://zoom.us/client/latest/zoom_x86_64.rpm"

log_info "Visual Studio Code"
dnf_write_repo_if_absent /etc/yum.repos.d/vscode.repo \
"[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" \
"https://packages.microsoft.com/keys/microsoft.asc"
dnf_install_if_missing code

log_info "ProtonVPN"
fedora_ver="$(rpm -E %fedora)"
dnf_install_rpm_url_if_missing protonvpn-stable-release \
    "https://repo.protonvpn.com/fedora-${fedora_ver}-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.2-1.noarch.rpm"
sudo dnf check-update --refresh &>/dev/null || true
dnf_install_if_missing proton-vpn-gnome-desktop

log_info "Spotify (no official Fedora repo, using Flatpak)"
flatpak_install_if_missing com.spotify.Client

log_info "GitHub Desktop (community shiftkey/desktop repo, not GitHub-official)"
dnf_write_repo_if_absent /etc/yum.repos.d/shiftkey-packages.repo \
"[shiftkey-packages]
name=GitHub Desktop
baseurl=https://rpm.packages.shiftkey.dev/rpm/
enabled=1
gpgcheck=1
gpgkey=https://rpm.packages.shiftkey.dev/gpg.key
repo_gpgcheck=1" \
"https://rpm.packages.shiftkey.dev/gpg.key"
dnf_install_if_missing github-desktop

log_info "Signal (no official rpm, using Flatpak - Signal-cooperative on Flathub)"
flatpak_install_if_missing org.signal.Signal

log_info "Claude Code"
dnf_install_if_missing nodejs npm
if ! command_exists claude; then
    sudo npm install -g @anthropic-ai/claude-code
else
    log_info "Claude Code already installed (run 'sudo npm update -g @anthropic-ai/claude-code' to update)"
fi

# ---------------------------------------------------------------------------
# 5. Quality-of-life tools
# ---------------------------------------------------------------------------
log_info "Quality-of-life tools"
dnf_install_if_missing gedit tree htop glances most libreoffice

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
sudo dnf upgrade --refresh -y
sudo dnf autoremove -y

# ---------------------------------------------------------------------------
# 9. Reboot prompt
# ---------------------------------------------------------------------------
confirm_reboot_prompt
