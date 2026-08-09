#!/usr/bin/env bash
# Shared helpers sourced by Gnome_Setup.sh, Fedora_Setup.sh and Kali_Setup.sh.
# This file is not meant to be executed directly.

TERMINAL_CUSTOMIZATION_REPO="https://github.com/cameronww7/Terminal-Customization"
TERMINAL_CUSTOMIZATION_DIR="/opt/Terminal-Customization"
SUDOERS_DROPIN="/etc/sudoers.d/99-linux-system-setup"

log_info()  { printf '\n[*] %s\n' "$*"; }
log_warn()  { printf '\n[!] %s\n' "$*" >&2; }
log_error() { printf '\n[x] %s\n' "$*" >&2; }

command_exists() {
    command -v "$1" &>/dev/null
}

# Creates /opt as a shared, group-writable (not world-writable) directory so
# later steps can git clone into it without needing sudo for every clone.
ensure_opt_dir() {
    if [[ ! -d /opt ]] || [[ "$(stat -c '%a' /opt)" != "2775" ]]; then
        log_info "Preparing /opt (group-writable, setgid)"
        sudo install -d -m 2775 -o "$USER" -g "$(id -gn)" /opt
    fi
}

# $1 = repo URL, $2 = destination dir
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

clone_terminal_customization() {
    ensure_opt_dir
    git_clone_or_update "$TERMINAL_CUSTOMIZATION_REPO" "$TERMINAL_CUSTOMIZATION_DIR"
}

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

    if ! sudo visudo -c -f "$SUDOERS_DROPIN" &>/dev/null; then
        log_error "Generated $SUDOERS_DROPIN failed visudo syntax check, removing it"
        sudo rm -f "$SUDOERS_DROPIN"
        return 1
    fi
}

confirm_reboot_prompt() {
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
