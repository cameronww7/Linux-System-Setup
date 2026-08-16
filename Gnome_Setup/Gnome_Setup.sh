#!/usr/bin/env bash
# Gnome_Setup.sh - provisions a fresh Debian/Ubuntu-family desktop running
# GNOME with everything needed for day-to-day development and daily use:
# system updates, core dev tools, a browser, the productivity apps in daily
# rotation, and a few quality-of-life packages.
#
# Why a script instead of a manual checklist: setting up a new machine by
# hand means re-remembering a dozen install commands from memory, forgetting
# one, and ending up with a box that's subtly different from your last one.
# This script IS the checklist, automated and safe to re-run, so "set up a
# new GNOME machine" is one command instead of an afternoon of clicking
# through app stores and copy-pasting install commands.
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
#     idempotency plumbing that both Gnome_Setup.sh and Fedora_Setup.sh
#     need, git clone/update, sudo config, the reboot prompt, all of that
#     is defined once there and sourced here. If you're tempted to add a
#     new "check if X is already done" helper, look there first.
#
# Usage: ./Gnome_Setup.sh
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

# --- apt-specific idempotency helpers -------------------------------------
# These four helpers are how every apt-based install below stays idempotent
# and secure. Read through them once, everything past this point is just
# these four functions called over and over with different arguments.

# Installs whichever of the given packages aren't already installed,
# skipping the ones dpkg already knows about. $@ = package names.
# Batches everything into a single apt-get install call instead of one call
# per package: apt resolves shared dependencies once instead of repeatedly,
# and you get one transaction in the apt history instead of a dozen.
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

# Adds a third-party apt repo's signing key as an ascii-armored (.asc/.gpg
# --armor) key, the format most vendors publish. $1 = key URL, $2 =
# destination keyring path.
#
# Why not apt-key: apt-key is deprecated and, more importantly, was a
# security footgun, every key it held was trusted for every repo on the
# system, so one compromised or malicious repo's key could vouch for
# packages from any other repo too. The modern approach (used by every
# apt_add_keyring_*/apt_add_source_list pair below) puts each vendor's key
# in its own file and references it explicitly via signed-by= in that one
# repo's source line, so a key only ever vouches for the repo it belongs to.
apt_add_keyring_asc() {
    local key_url="$1" keyring="$2"
    if [[ ! -f "$keyring" ]]; then
        log_info "Adding keyring: $keyring"
        curl -fsSL "$key_url" | gpg --dearmor | sudo tee "$keyring" >/dev/null
    fi
}

# Same idea as apt_add_keyring_asc, but for vendors that publish their key
# already in gpg's binary format, no `gpg --dearmor` conversion needed, just
# download it straight to the keyring path. $1 = key URL, $2 = destination
# keyring path.
apt_add_keyring_bin() {
    local key_url="$1" keyring="$2"
    if [[ ! -f "$keyring" ]]; then
        log_info "Adding keyring: $keyring"
        sudo curl -fsSLo "$keyring" "$key_url"
    fi
}

# Writes a one-line apt source file if it doesn't already contain the given
# deb line, then refreshes apt so the new repo is usable right away. $1 =
# sources.list.d file, $2 = deb line (normally including a
# signed-by=<keyring path> pointing at whatever apt_add_keyring_* wrote).
# Written by hand instead of using `add-apt-repository`: that tool doesn't
# handle custom signed-by lines well and would pull in
# software-properties-common as a dependency just for this, a plain file
# write does the same job with nothing extra needed.
apt_add_source_list() {
    local list_file="$1" deb_line="$2"
    if [[ ! -f "$list_file" ]] || ! grep -qF "$deb_line" "$list_file"; then
        log_info "Adding apt source: $list_file"
        echo "$deb_line" | sudo tee "$list_file" >/dev/null
        sudo apt-get update
    fi
}

# For apps that only ship a bare .deb file with no apt repo behind it at
# all (Discord and Zoom below). Downloads to a temp file and installs with
# apt-get, not dpkg -i, on purpose: apt-get install on a local .deb path
# still resolves and installs any missing dependencies automatically, while
# `dpkg -i` alone would leave the package half-broken and require a
# separate `apt --fix-broken install` afterward. $1 = dpkg package name to
# check, $2 = .deb download URL.
apt_install_deb_url_if_missing() {
    local pkg="$1" url="$2" tmp_deb
    if dpkg -s "$pkg" &>/dev/null; then
        log_info "$pkg already installed, skipping"
        return
    fi
    tmp_deb="$(mktemp --suffix=.deb)"
    log_info "Downloading $pkg from $url"
    # No -s here on purpose, unlike the small keyring downloads elsewhere in
    # this file: Discord and Zoom's .deb files are large enough (tens to
    # ~100+ MB) that a silent download can sit there for a while with
    # nothing on screen. --progress-bar keeps a live download indicator
    # visible instead.
    curl -f --progress-bar -Lo "$tmp_deb" "$url"
    sudo apt-get install -y "$tmp_deb"
    rm -f "$tmp_deb"
}

# ---------------------------------------------------------------------------
# 1. System update
# ---------------------------------------------------------------------------
# Always do this first. Updating and upgrading before installing anything
# new means every step below is working against current package metadata
# and current versions, instead of fighting a stale cache or installing on
# top of an already-outdated base system.
log_info "System update"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y

# ---------------------------------------------------------------------------
# 2. Base dev tools
# ---------------------------------------------------------------------------
# The baseline every other step, and honestly most day-to-day work, ends up
# assuming exists: a compiler toolchain, Python, git, and the headers a lot
# of pip packages need to build native extensions against (libpcap-dev in
# particular is a common one for anything touching packet capture).
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
# The apps installed on every machine of mine, day one. Notice the install
# method isn't identical line to line, that's not inconsistency, it's each
# app using whichever method its own vendor actually supports well: a real
# signed apt repo where one exists (Slack, VS Code, Spotify, Signal), a bare
# .deb with no repo behind it at all when that's all the vendor ships
# (Discord, Zoom), and ProtonVPN's own special case just below (a bootstrap
# package that adds a repo, rather than being the app itself). Follow which
# helper each block below actually calls to see which category it falls
# into.
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
# Doesn't use apt_install_deb_url_if_missing like the others above: the
# downloaded .deb only bootstraps ProtonVPN's own apt repo, it isn't the app
# itself, so "already done" has to mean "the repo file exists" instead of
# "the dpkg package is installed". The actual app installs on the next line.
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

log_info "Signal"
apt_add_keyring_asc "https://updates.signal.org/desktop/apt/keys.asc" /usr/share/keyrings/signal-desktop-keyring.gpg
apt_add_source_list /etc/apt/sources.list.d/signal-xenial.list \
    "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main"
apt_install_if_missing signal-desktop

log_info "Claude Code"
apt_install_if_missing nodejs npm
# Claude Code isn't distributed via apt, it's an npm global install, so it
# gets its own command_exists check rather than going through
# apt_install_if_missing like everything else in this section. Checking
# explicitly (instead of just always running npm install -g, which would
# also work but re-runs unnecessarily) keeps the "already done, skip it"
# behavior consistent with every other step in this script, and the log
# message tells you the update command since there's no apt upgrade path
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
apt_install_if_missing gedit tree htop glances most libreoffice terminator

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
# added new apt repos. Those repos' own packages (and anything else that
# became available in the meantime) wouldn't be picked up by the update at
# the top of this script, catching it now means the very first `apt
# upgrade` you run by hand after this finishes isn't a surprisingly large one.
log_info "Final update pass"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y

# ---------------------------------------------------------------------------
# 10. Reboot prompt
# ---------------------------------------------------------------------------
# See confirm_reboot_prompt in lib/common.sh for why a reboot is actually
# worth offering here rather than just ending the script.
confirm_reboot_prompt
