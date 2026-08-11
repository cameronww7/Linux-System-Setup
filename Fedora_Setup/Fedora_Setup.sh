#!/usr/bin/env bash
# Fedora_Setup.sh - provisions a fresh Fedora desktop running GNOME with
# everything needed for day-to-day development and daily use: system
# updates, core dev tools, a browser, the productivity apps in daily
# rotation, and a few quality-of-life packages.
#
# This script mirrors Gnome_Setup.sh section-for-section on purpose, same
# machine role, same install order, same reasoning behind every decision,
# just through dnf/rpm instead of apt/deb because that's what Fedora uses.
# If you're editing one of these two scripts, check whether the same change
# makes sense in the other one too, and if you're trying to understand why
# something here is done a certain way, Gnome_Setup.sh's comments likely
# already explain the apt-world equivalent of the same reasoning.
#
# A few design decisions worth understanding before you edit this file:
#   - Idempotent: every install/config step below checks "is this already
#     done?" before doing anything. That means you can re-run this script
#     any time, after a failure partway through, to pick up a new section
#     someone added later, to catch a machine up that's fallen behind, and
#     it will only do the work that's still actually needed instead of
#     erroring out on things that already exist.
#   - Self-locating: SCRIPT_DIR/REPO_ROOT below figure out where this repo
#     actually lives on disk at runtime (see the comment above them), so
#     cloning this repo to a different path, or running the script from a
#     different working directory, never breaks the `source lib/common.sh`
#     line further down.
#   - Shared helpers live in lib/common.sh, not in this file. Logging,
#     idempotency plumbing that both Fedora_Setup.sh and Gnome_Setup.sh
#     need, git clone/update, sudo config, the reboot prompt, all of that
#     is defined once there and sourced here. If you're tempted to add a
#     new "check if X is already done" helper, look there first.
#
# Usage: ./Fedora_Setup.sh
# Run as your normal user, NOT with sudo, see the EUID check just below for
# why that matters. Individual steps call sudo internally, only for the
# specific commands that actually need root, package installs, writing
# under /etc, and so on.

set -euo pipefail
# -e: stop immediately on any command that fails, instead of plowing ahead
#     with a half-finished setup.
# -u: treat referencing an unset variable as an error, catches typos in
#     variable names before they cause a confusing failure somewhere else.
# -o pipefail: a pipeline (a | b) fails if ANY stage fails, not just the
#     last one, so a failure early in a pipe can't get silently swallowed.

if [[ $EUID -eq 0 ]]; then
    # Running this whole script as root would mean every "user-scoped" step
    # below (npm -g installs, the ~/Dev folder, git clones under $HOME) ends
    # up owned by root instead of you, which is exactly the kind of mess
    # that's annoying to untangle later. Individual commands below call
    # sudo themselves for the specific things that actually need root, so
    # there's no reason to run the whole script elevated.
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

# --- dnf-specific idempotency helpers --------------------------------------
# These four helpers are how every dnf-based install below stays idempotent.
# Read through them once, everything past this point is just these four
# functions called over and over with different arguments, the same
# structure as the apt helpers in Gnome_Setup.sh, adapted to dnf/rpm.

# Installs whichever of the given packages aren't already installed,
# skipping the ones rpm already knows about. $@ = package names.
# Batches everything into a single dnf install call instead of one call per
# package: dnf resolves shared dependencies once instead of repeatedly, and
# you get one transaction instead of a dozen.
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

# Same idea as dnf_install_if_missing but for dnf "groups" (bundles of
# related packages dnf tracks as a single unit, like Development Tools
# below), which don't show up in a plain `rpm -q` check the way individual
# packages do. $1 = group name, exactly as dnf lists it.
dnf_group_install_if_missing() {
    local group="$1"
    if dnf group list --installed 2>/dev/null | grep -qF "$group"; then
        log_info "Group already installed, skipping: $group"
    else
        log_info "Installing group: $group"
        sudo dnf groupinstall -y "$group"
    fi
}

# For apps distributed as a standalone rpm URL rather than through a repo
# (Zoom below, and the ProtonVPN bootstrap package). Just hands the URL
# straight to dnf rather than downloading it manually first, dnf can
# install directly from a URL and will resolve and pull in any dependencies
# that rpm needs on its own. $1 = package name to check, $2 = rpm URL.
dnf_install_rpm_url_if_missing() {
    local pkg="$1" url="$2"
    if rpm -q "$pkg" &>/dev/null; then
        log_info "$pkg already installed, skipping"
        return
    fi
    log_info "Installing $pkg from $url"
    sudo dnf install -y "$url"
}

# Writes a .repo file under /etc/yum.repos.d/ if one doesn't already exist
# at that path, importing the vendor's gpg key first so dnf trusts packages
# from it. This is dnf's equivalent of Gnome_Setup.sh's
# apt_add_keyring_*/apt_add_source_list pair, one function instead of two
# because dnf's repo file format bundles the key reference and repo
# metadata together, there's no separate apt-style keyring file to manage.
# $1 = /etc/yum.repos.d/*.repo path, $2 = repo file contents, $3 = gpg key
# URL to import.
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

# ---------------------------------------------------------------------------
# 1. System update
# ---------------------------------------------------------------------------
# Always do this first. Updating and upgrading before installing anything
# new means every step below is working against current package metadata
# and current versions, instead of fighting a stale cache or installing on
# top of an already-outdated base system. --refresh forces dnf to actually
# re-check upstream metadata instead of trusting whatever it last cached.
log_info "System update"
sudo dnf upgrade --refresh -y
sudo dnf autoremove -y

# ---------------------------------------------------------------------------
# 2. Base dev tools
# ---------------------------------------------------------------------------
# The baseline every other step, and honestly most day-to-day work, ends up
# assuming exists: a compiler toolchain (the Development Tools group,
# Fedora's equivalent of Debian's build-essential), Python, git, and the
# headers a lot of pip packages need to build native extensions against
# (libpcap-devel in particular is a common one for anything touching packet
# capture).
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
# Same app list as Gnome_Setup.sh, but Fedora's ecosystem doesn't have an
# official rpm/dnf-repo option for every one of them, so the install method
# splits into three groups here: a real dnf repo where one exists (Brave,
# VS Code, and ProtonVPN's own bootstrap repo below), a direct rpm URL when
# that's all the vendor ships (Zoom), and Flatpak/Flathub as the fallback
# for apps with no native Fedora package at all (Discord, Slack, Spotify,
# Signal). Each Flatpak call below has a log_info line saying exactly why
# it's not going through dnf instead.
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
# Two-step install: the rpm below only bootstraps ProtonVPN's own dnf repo,
# it isn't the app itself (dnf_install_rpm_url_if_missing checks for the
# protonvpn-stable-release package, not proton-vpn-gnome-desktop). The
# check-update --refresh forces dnf to pick up that new repo's metadata
# immediately, otherwise the dnf_install_if_missing call below could still
# be looking at stale cache and fail to find the actual app package.
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
# Claude Code isn't distributed via dnf, it's an npm global install, so it
# gets its own command_exists check rather than going through
# dnf_install_if_missing like everything else in this section. Checking
# explicitly (instead of just always running npm install -g, which would
# also work but re-runs unnecessarily) keeps the "already done, skip it"
# behavior consistent with every other step in this script, and the log
# message tells you the update command since there's no dnf upgrade path
# that would catch this one.
if ! command_exists claude; then
    sudo npm install -g @anthropic-ai/claude-code
else
    log_info "Claude Code already installed (run 'sudo npm update -g @anthropic-ai/claude-code' to update)"
fi

# ---------------------------------------------------------------------------
# 5. Quality-of-life tools
# ---------------------------------------------------------------------------
# Small utilities that make the box nicer to actually live in day to day: a
# lightweight text editor for quick edits, better process/disk visibility
# than the bare coreutils give you, a friendlier pager, two terminal
# emulators, and enough of an office suite to open something someone
# emails you without reaching for another machine.
log_info "Quality-of-life tools"
# Unlike Gnome_Setup.sh, ghostty doesn't need a Flatpak fallback here:
# Fedora carries it in its official repos, so a plain dnf install works.
dnf_install_if_missing gedit tree htop glances most libreoffice terminator ghostty

# ---------------------------------------------------------------------------
# 6. Terminal customization
# ---------------------------------------------------------------------------
# Only clones the repo here, deliberately doesn't run or configure anything
# from it. Shell prompt/plugin setup is a matter of personal taste that
# changes far more often than a system provisioning script should, keeping
# that logic in its own repo means updating your shell config never
# requires touching (or re-running) this script. See that repo's own
# README for how to actually apply it once it's cloned.
log_info "Terminal customization"
clone_terminal_customization

# ---------------------------------------------------------------------------
# 7. ~/Dev folder
# ---------------------------------------------------------------------------
# A blank slate for your own projects. Deliberately separate from /opt
# (reserved for the tool installs this script itself manages), so nothing
# you create here is ever at risk of being touched by a future re-run.
log_info "Dev folder"
mkdir -p "$HOME/Dev"

# ---------------------------------------------------------------------------
# 8. Sudo lecture / pwfeedback
# ---------------------------------------------------------------------------
# See add_sudo_lecture_config in lib/common.sh for what this actually
# configures and why it's done as a sudoers.d drop-in.
add_sudo_lecture_config "$REPO_ROOT"

# ---------------------------------------------------------------------------
# 9. Final update pass
# ---------------------------------------------------------------------------
# Runs again at the end, not just at the start, because several steps above
# added new dnf repos. Those repos' own packages (and anything else that
# became available in the meantime) wouldn't be picked up by the update at
# the top of this script, catching it now means the very first `dnf
# upgrade` you run by hand after this finishes isn't a surprisingly large one.
log_info "Final update pass"
sudo dnf upgrade --refresh -y
sudo dnf autoremove -y

# ---------------------------------------------------------------------------
# 10. Reboot prompt
# ---------------------------------------------------------------------------
# See confirm_reboot_prompt in lib/common.sh for why a reboot is actually
# worth offering here rather than just ending the script.
confirm_reboot_prompt
