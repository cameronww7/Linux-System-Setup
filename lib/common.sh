#!/usr/bin/env bash
# common.sh - shared helper functions for every provisioning script in this
# repo (Gnome_Setup.sh, Fedora_Setup.sh, Kali_Setup.sh).
#
# Why this file exists: all three scripts need to solve the same handful of
# problems, log messages consistently, check "is this already installed?"
# before doing anything, clone-or-update a git repo without clobbering local
# state, set up the shared /opt directory, configure sudo the same way, and
# offer a reboot at the end. Older versions of this repo had that logic
# copy-pasted into each script separately, and they drifted: one script
# would get a bugfix the other never did, and the two ended up behaving
# differently for no good reason. Putting the shared logic here once means
# a fix or improvement made here benefits all three scripts automatically.
#
# If you're adding a new idempotency helper (an "install X if it isn't
# already installed" style function), check here first before writing one
# in a specific script, there's a decent chance Fedora_Setup.sh or
# Kali_Setup.sh will eventually want the same thing.
#
# This file is not meant to be executed directly, only sourced. Every
# provisioning script starts with this pattern:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
#   source "$REPO_ROOT/lib/common.sh"
# That's what lets this repo be cloned to any path and run from any working
# directory, nothing here (or in the scripts that source it) hardcodes
# where the repo lives on disk.

TERMINAL_CUSTOMIZATION_REPO="https://github.com/cameronww7/Terminal-Customization"
TERMINAL_CUSTOMIZATION_DIR="/opt/Terminal-Customization"
SUDOERS_DROPIN="/etc/sudoers.d/99-linux-system-setup"

# Three log levels, each with its own bracketed tag ([*]/[!]/[x]) so the
# output is easy to scan and easy to grep. Warnings and errors go to stderr,
# not stdout, so redirecting a run's normal output to a log file still lets
# problems show up on the terminal.
log_info()  { printf '\n[*] %s\n' "$*"; }
log_warn()  { printf '\n[!] %s\n' "$*" >&2; }
log_error() { printf '\n[x] %s\n' "$*" >&2; }

# `command -v` checks the current $PATH the same way the shell would when
# you actually run the command, which is what we care about here, not just
# whether a package happens to be installed (a package can be installed
# with its binary somewhere unusual, or a binary can exist without its
# "parent" package being installed at all, e.g. something built from source).
command_exists() {
    command -v "$1" &>/dev/null
}

# Creates /opt as a shared, group-writable (not world-writable) directory so
# later steps can git clone into it without needing sudo for every clone.
# 2775 = rwxrwsr-x: the setgid bit (the leading 2) makes every new file or
# folder created inside /opt inherit /opt's group instead of the creating
# user's default group, so clones made by different tools/steps stay
# consistently group-writable without each one having to set that itself.
# That's the difference between this and a blunt `chmod 777`, which would
# also let any user on the box write here, not just the group we intend.
ensure_opt_dir() {
    if [[ ! -d /opt ]] || [[ "$(stat -c '%a' /opt)" != "2775" ]]; then
        log_info "Preparing /opt (group-writable, setgid)"
        sudo install -d -m 2775 -o "$USER" -g "$(id -gn)" /opt
    fi
}

# Clones a repo if it isn't there yet, or fast-forward pulls it if it is.
# $1 = repo URL, $2 = destination dir.
# --ff-only instead of a plain `git pull` is deliberate: these are tool
# repos we don't expect local changes in. If a fast-forward isn't possible
# (upstream history was rewritten, or someone made local edits by hand),
# this fails loudly instead of silently creating a merge commit or, worse,
# silently overwriting something you meant to keep.
git_clone_or_update() {
    local repo_url="$1" dest_dir="$2"
    if [[ -d "$dest_dir/.git" ]]; then
        log_info "Updating existing clone: $dest_dir"
        git -C "$dest_dir" pull --ff-only
    else
        log_info "Cloning $repo_url -> $dest_dir"
        mkdir -p "$(dirname "$dest_dir")"
        git clone "$repo_url" "$dest_dir"
    fi
}

# Thin, purpose-specific wrapper around git_clone_or_update so every script
# that wants Terminal-Customization available doesn't need to know its repo
# URL or its install path, both live in the two constants at the top of
# this file. Change either one in exactly one place if it ever needs to move.
clone_terminal_customization() {
    ensure_opt_dir
    git_clone_or_update "$TERMINAL_CUSTOMIZATION_REPO" "$TERMINAL_CUSTOMIZATION_DIR"
}

# Configures two small sudo quality-of-life settings: pwfeedback (show
# asterisks while typing your password, most distros ship this off by
# default) and a lecture message shown on every sudo call, not just the
# first one per session/machine like sudo's own default behavior.
#
# Why a sudoers.d drop-in instead of editing /etc/sudoers directly: a typo
# in /etc/sudoers itself can leave sudo completely broken for everyone on
# the machine, with no working sudo left to fix sudo with. Drop-in files
# under /etc/sudoers.d/ are included automatically, get validated
# independently (see the visudo -c check below), and if something's wrong
# with this one specifically, it's a single file to delete rather than a
# live edit to a file you really cannot afford to get wrong.
#
# $1 = REPO_ROOT of the calling script, used to locate lib/sudo_lecture.txt
add_sudo_lecture_config() {
    local repo_root="$1"
    local lecture_src="$repo_root/lib/sudo_lecture.txt"

    log_info "Configuring sudo pwfeedback + lecture message"
    sudo cp "$lecture_src" /etc/sudo_lecture.txt

    sudo install -m 0440 /dev/stdin "$SUDOERS_DROPIN" <<-EOF
	Defaults    pwfeedback
	Defaults    lecture=always
	Defaults    lecture_file=/etc/sudo_lecture.txt
	EOF

    # Belt and suspenders: syntax-check the file we just wrote before
    # trusting it. sudo silently ignores an invalid drop-in with just a
    # warning rather than failing outright, so without this check a typo
    # here could sit unnoticed instead of being caught immediately.
    if ! sudo visudo -c -f "$SUDOERS_DROPIN" &>/dev/null; then
        log_error "Generated $SUDOERS_DROPIN failed visudo syntax check, removing it"
        sudo rm -f "$SUDOERS_DROPIN"
        return 1
    fi
}

# Installs flatpak itself if it's not present, then adds the Flathub remote
# if it's missing. Flathub specifically, rather than some other flatpak
# remote, because it's the de facto default: it's where nearly every app
# that publishes a flatpak actually publishes it, and it's the one every
# flatpak_install_if_missing call in these scripts assumes exists.
# Called internally by flatpak_install_if_missing, no need to call this one
# directly.
ensure_flatpak_flathub() {
    command_exists flatpak || {
        log_info "Installing flatpak"
        if command_exists dnf; then
            sudo dnf install -y flatpak
        else
            sudo apt-get install -y flatpak
        fi
    }
    if ! flatpak remote-list 2>/dev/null | grep -q '^flathub'; then
        log_info "Adding Flathub remote"
        sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
}

# Fallback install path for apps that don't publish a native apt/dnf package
# for the distro this is running on (checked case by case in each caller,
# search each script for "Flatpak" to see exactly which apps and why).
# $1 = flatpak app id. $2 (optional) = the binary name that app's official
# installer normally puts on $PATH (e.g. "discord", "slack"). When given,
# checked via command_exists first so a copy installed some other way (the
# vendor's own .deb/.rpm, a manual download, a snap) is recognized instead
# of Flatpak installing a second, separate copy alongside it. A flatpak
# install exports its own launcher through flatpak, not onto $PATH, so this
# check and the flatpak-list check below don't overlap or double-count.
flatpak_install_if_missing() {
    local app_id="$1" bin_name="${2:-}"
    if [[ -n "$bin_name" ]] && command_exists "$bin_name"; then
        log_info "$bin_name already installed outside flatpak, skipping $app_id"
        return
    fi
    ensure_flatpak_flathub
    if flatpak list --app 2>/dev/null | grep -q "$app_id"; then
        log_info "$app_id already installed (flatpak), skipping"
    else
        log_info "Installing $app_id via flatpak"
        sudo flatpak install -y flathub "$app_id"
    fi
}

# Installs snapd if it's not present, then makes sure classic-confinement
# snaps (the confinement level any real GUI/terminal app needs, --classic
# below) actually work. Two things dnf-based systems don't get for free the
# way apt-based ones do, confirmed by testing both directly:
#   - Fedora doesn't wire up the /snap -> /var/lib/snapd/snap symlink
#     automatically the way Ubuntu does. snapd installs and runs fine
#     without it, but every classic snap fails to resolve its own libraries
#     without that symlink in place.
#   - A freshly installed snapd needs a moment to finish its first-boot
#     "seeding" before it'll accept any install. Skip the wait and
#     `snap install` fails outright with "too early for operation, device
#     not yet seeded", `snap wait system seed.loaded` blocks until it's
#     safe to proceed, and returns immediately if seeding already finished.
ensure_snapd() {
    command_exists snap || {
        log_info "Installing snapd"
        if command_exists dnf; then
            sudo dnf install -y snapd
        else
            sudo apt-get install -y snapd
        fi
        sudo systemctl enable --now snapd.socket
    }
    if command_exists dnf && [[ ! -e /snap ]]; then
        log_info "Linking /snap -> /var/lib/snapd/snap (Fedora needs this for classic snaps, Ubuntu/Debian already have it)"
        sudo ln -s /var/lib/snapd/snap /snap
    fi
    sudo snap wait system seed.loaded
}

# Fallback install path for apps that don't have a real apt/dnf package OR a
# working Flatpak, used specifically where even Flatpak isn't an option
# (Ghostty as of writing: it has no Flathub listing at all despite reserving
# an app id for one, see the comment above each call site for the full
# story). $1 = snap package name. $2 (optional) = the binary name that
# app's official installer normally puts on $PATH, same idea as
# flatpak_install_if_missing's $2, checked first so a copy installed some
# other way isn't duplicated. Note the "already installed" check below
# queries snapd directly (`snap list`) rather than using $2/command_exists
# for that half of the job: a snap's own binary is only added to $PATH via
# a profile.d script that a currently-running shell won't have re-sourced,
# so command_exists would wrongly report "not installed" immediately after
# a real, successful install within the same script run.
snap_install_if_missing() {
    local snap_name="$1" bin_name="${2:-}"
    if [[ -n "$bin_name" ]] && command_exists "$bin_name"; then
        log_info "$bin_name already installed outside snap, skipping $snap_name"
        return
    fi
    ensure_snapd
    if snap list "$snap_name" &>/dev/null; then
        log_info "$snap_name already installed (snap), skipping"
    else
        # --classic: unconfined/full-system-access. Required for
        # $snap_name here (snapd refuses a plain confined install for
        # packages that declare classic confinement), and it's the correct
        # choice anyway, a terminal emulator has to spawn arbitrary shells
        # and processes, so sandboxing it wouldn't accomplish much.
        log_info "Installing $snap_name via snap"
        sudo snap install --classic "$snap_name"
    fi
}

# Offers to reboot once everything else is done. Genuinely worth asking for,
# not just a nicety: kernel/systemd updates from the "update" steps in each
# script don't take effect until reboot, new group memberships (docker,
# wireshark, etc, if a script ever adds one) need a fresh login session to
# apply, and the sudoers changes made by add_sudo_lecture_config are the
# kind of thing you want to confirm actually took effect cleanly.
confirm_reboot_prompt() {
    # Lets a non-interactive or chained run (CI, a provisioning tool calling
    # this script for you) skip the interactive prompt and just reboot.
    if [[ "${AUTO_REBOOT:-}" == "yes" ]]; then
        log_info "AUTO_REBOOT=yes set, rebooting now"
        sudo reboot
        return
    fi

    if [[ ! -t 0 ]]; then
        log_warn "Setup finished. Non-interactive shell detected, skipping reboot prompt. Reboot manually when convenient."
        return
    fi

    read -r -p $'\nSetup finished. Reboot now? [y/N] ' reply
    case "$reply" in
        [yY]|[yY][eE][sS]) sudo reboot ;;
        *) log_info "Skipping reboot. Remember to reboot before relying on all changes." ;;
    esac
}
