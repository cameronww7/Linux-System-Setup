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

# Installs a dnf "group" (a bundle of related packages dnf tracks as a
# single unit, like Development Tools below). $1 = group ID, the short
# kebab-case identifier (e.g. "development-tools"), NOT the display name
# ("Development Tools") shown by `dnf group list`. Confirmed by testing
# directly: dnf5's `group install` subcommand only resolves by ID, unlike
# dnf4's `groupinstall`, which matched on the display name. Passing the
# display name fails outright with "No match for argument", it doesn't
# fall back to a fuzzy/name match.
#
# Unlike dnf_install_if_missing, there's no separate "already installed?"
# pre-check here, on purpose, after two rounds of trying to add one: a
# `dnf group list --installed | grep` pre-check isn't actually cheap (it
# still needs a full repo metadata reload, the same "Updating and loading
# repositories..." step any dnf command pays for), so it bought nothing
# over just running the real install, and its own status output was
# getting silently swallowed by the pipe into grep, which is exactly the
# kind of unexplained silent pause that looks like a hang. Confirmed by
# testing directly that it's also not reliable: it reported a group as
# not-installed when it actually already was. `dnf group install` is
# already idempotent on its own, running it against an already-installed
# group just prints "Group ... is already installed" / "Nothing to do."
# and exits 0, with normal visible dnf output the whole time, so it's
# simpler and more honest to just always call it.
# Uses the space-separated "group install" subcommand form rather than the
# older concatenated "groupinstall", since dnf5 (the default on modern
# Fedora, where plain `dnf` IS dnf5) dropped the concatenated form entirely.
# "group install" works on both dnf5 and legacy dnf4.
dnf_group_install() {
    local group="$1"
    log_info "Installing group: $group"
    sudo dnf group install -y "$group"
}

# For apps distributed as a standalone rpm URL rather than through a repo
# (Zoom below, and the ProtonVPN bootstrap package). Just hands the URL
# straight to dnf rather than downloading it manually first, dnf can
# install directly from a URL and will resolve and pull in any dependencies
# that rpm needs on its own. $1 = package name to check, $2 = rpm URL, $3
# (optional) = the vendor's public GPG key URL.
#
# $3 matters more than it looks: both Zoom's and ProtonVPN's rpms actually
# are signed, confirmed directly with `rpm -K` against the real downloaded
# files, but without $3 the signing key was never imported, so dnf/rpm had
# no way to check that signature and silently installed both unverified
# every run. Importing the real key first (confirmed against Zoom's and
# ProtonVPN's own published key URLs, fingerprints match what the
# downloaded rpms are actually signed with) turns this into a real
# verified install instead of a blind-trust one, `rpm -K` flips from
# "SIGNATURES NOT OK" to "digests signatures OK" once the key's imported.
dnf_install_rpm_url_if_missing() {
    local pkg="$1" url="$2" gpgkey_url="${3:-}"
    if rpm -q "$pkg" &>/dev/null; then
        log_info "$pkg already installed, skipping"
        return
    fi
    if [[ -n "$gpgkey_url" ]]; then
        log_info "Importing signing key for $pkg"
        sudo rpm --import "$gpgkey_url"
    fi
    log_info "Installing $pkg from $url"
    sudo dnf install -y "$url"
}

# Enables a Fedora COPR (Cool Other Package Repo) if it isn't already
# enabled. A COPR is Fedora Project infrastructure (builds run on Fedora's
# own COPR build servers, from a public, inspectable spec, GPG-signed with
# a COPR-issued per-project key), but it's still an individual's personal
# repo, not reviewed or held to any quality/security bar by Fedora itself,
# explicitly disclaimed in COPR's own FAQ. Lower-trust than an official
# Fedora or RPM Fusion repo, or even a vendor's own official repo, treat it
# accordingly, this is the one place in this script that reaches for one,
# and only after confirming directly that nothing higher in the chain (an
# official repo, RPM Fusion, Flathub) actually has the package. $1 = COPR
# name in owner/project form (e.g. "scottames/ghostty").
dnf_copr_enable_if_missing() {
    local copr="$1" repo_file
    repo_file="/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:${copr/\//:}.repo"
    if [[ -f "$repo_file" ]]; then
        log_info "COPR already enabled, skipping: $copr"
        return
    fi
    log_info "Enabling COPR (community-maintained, lower-trust than official repos): $copr"
    sudo dnf copr enable -y "$copr"
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
    # -y matters here specifically, not just for consistency with every
    # other dnf call in this script: dnf5 does its own separate key-trust
    # check for repo_gpgcheck (verifying repomd.xml itself, on top of the
    # rpm --import above, which only covers individual package signatures),
    # and re-fetches/imports the key from the repo's own gpgkey= URL to do
    # it. Without -y, dnf5 prints "Signing key not found" and waits on a
    # y/N import prompt that never gets an answer in a non-interactive run,
    # confirmed by reproducing it directly: the exact same repo config
    # succeeds immediately once -y is present.
    sudo dnf makecache -y
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
dnf_group_install "development-tools"

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
# splits into three trust tiers here, in priority order, dnf/RPM Fusion
# first, Flatpak second, Snap/COPR only when neither above has it, a raw
# binary/script never (nothing below needs one):
#   - A real vendor-published dnf repo (Brave, VS Code, and ProtonVPN's own
#     bootstrap repo below). Not Fedora's own repos and not RPM Fusion, but
#     the vendor's own signed infrastructure, still meaningfully different
#     from, and more trustworthy than, an individual's unreviewed COPR.
#   - A signed rpm from a direct URL when that's all the vendor ships
#     (Zoom, and ProtonVPN's bootstrap package), the signing key is
#     imported and verified first, see dnf_install_rpm_url_if_missing's
#     $3 above, confirmed directly with `rpm -K` that both are genuinely
#     signed and that these are the vendors' real keys.
#   - Flatpak/Flathub for apps with no native Fedora package at all
#     (Discord, Slack, Spotify, Signal). Checked each one's actual
#     manifest via Flathub's API (not assumed): none request the broad
#     --filesystem=host grant, but Discord, Slack, and Signal do request
#     --device=all (full device access, reasonable for apps doing
#     voice/video/screen-share, still worth knowing it's not a narrow
#     grant), and Discord's sockets list plain "x11" alongside "wayland"
#     rather than the safer "fallback-x11" the other three use, meaning it
#     can always reach X11 even under Wayland. Real sandboxing, not
#     equivalent to a native package's unrestricted access, but not a
#     rubber stamp either, know what's actually granted before calling
#     Flatpak "the safe choice."
log_info "Discord (no official rpm, using Flatpak, requests --device=all + unrestricted x11)"
flatpak_install_if_missing com.discordapp.Discord discord

log_info "Slack (no stable versioned rpm URL from Slack, using Flatpak, requests --device=all)"
flatpak_install_if_missing com.slack.Slack slack

log_info "Zoom"
dnf_install_rpm_url_if_missing zoom "https://zoom.us/client/latest/zoom_x86_64.rpm" \
    "https://zoom.us/linux/download/pubkey"

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
    "https://repo.protonvpn.com/fedora-${fedora_ver}-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.4-1.noarch.rpm" \
    "https://repo.protonvpn.com/fedora-${fedora_ver}-stable/public_key.asc"
log_info "Refreshing package metadata for the new ProtonVPN repo"
# Not silenced with &>/dev/null on purpose: this hits every enabled repo
# over the network, not just ProtonVPN's, so it can take a real few
# seconds, and with output fully suppressed there'd be nothing on screen
# the whole time it's running. || true is still needed either way: exit
# code 100 here just means "updates are available", a normal outcome, not
# a failure, and set -e would otherwise treat it as one.
sudo dnf check-update --refresh || true
dnf_install_if_missing proton-vpn-gnome-desktop

# Best-scoped Flatpak of the four in this section: devices is just "dri"
# (GPU access, not full device access), filesystem grants are read-only
# and limited to Music/Pictures, and it uses the safer "fallback-x11"
# socket instead of unconditional x11.
log_info "Spotify (no official Fedora repo, using Flatpak, narrowly scoped permissions)"
flatpak_install_if_missing com.spotify.Client spotify

log_info "Signal (no official rpm, using Flatpak - Signal-cooperative on Flathub, requests --device=all)"
flatpak_install_if_missing org.signal.Signal signal-desktop

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
dnf_install_if_missing gedit tree htop glances most libreoffice terminator

# Ghostty isn't actually in Fedora's official repos or RPM Fusion
# (confirmed directly, `dnf search ghostty` and `dnf list ghostty` both
# come up empty, an earlier version of this comment claimed otherwise and
# was wrong), and it isn't on Flathub either, despite reserving the app id
# com.mitchellh.ghostty for a submission that was never actually
# completed (confirmed directly: that app id 404s on Flathub and its
# search returns nothing).
#
# Following dnf > Flatpak > Snap > raw binary priority, the next thing to
# check before reaching for Snap is a Fedora COPR. scottames/ghostty
# checks out: its packages build on Fedora's own COPR infrastructure (not
# the maintainer's personal machine) from a public spec at
# github.com/scottames/copr, and are signed with a COPR-issued per-project
# key, confirmed directly via COPR's API and by importing and checking
# that key's fingerprint. Still lower-trust than an official repo, Fedora
# explicitly disclaims any quality/security review over COPR contents,
# and unlike Snap here Ghostty's own project doesn't specifically vouch
# for this build the way it does for the Snap's CI provenance, but a
# vetted COPR outranks Snap in the priority order regardless, so that's
# what's used. (For reference: the alternative would've been Snap,
# confinement "classic", i.e. no sandboxing attempted at all, not
# "degraded strict", terminal emulators need classic either way since
# they have to spawn arbitrary shells.)
log_info "Ghostty (no real dnf/RPM-Fusion package, no real Flatpak, using Fedora COPR: lower-trust than official repos)"
dnf_copr_enable_if_missing scottames/ghostty
dnf_install_if_missing ghostty

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
