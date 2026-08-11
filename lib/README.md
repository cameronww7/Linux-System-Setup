# 📦 lib

The shared helper library every setup script in this repo sources: [`Gnome_Setup.sh`](../Gnome_Setup/Gnome_Setup.sh), [`Fedora_Setup.sh`](../Fedora_Setup/Fedora_Setup.sh), and [`Kali_Setup.sh`](../Kali_Setup/Kali_Setup.sh) all start by pulling in `common.sh` from here. Nothing in this folder is meant to be run directly, `common.sh` only defines functions, it doesn't do anything on its own until a setup script sources and calls it.

## Why a shared library instead of copy-pasting

All three setup scripts need to solve the same handful of problems: log messages consistently, check "is this already installed?" before doing anything, clone-or-update a git repo without clobbering local changes, set up the shared `/opt` directory, configure sudo the same way, and offer a reboot at the end. Older versions of this repo had that logic copy-pasted into each script separately, and it drifted, a fix made in one script never made it to the other. Putting the shared logic here once means a bugfix or improvement made here benefits every script automatically, instead of needing to be repeated three times and inevitably forgotten in one of them.

If you're adding a new "install X if it isn't already installed" style helper, check here first before writing one inside a specific script. There's a decent chance the other two scripts will eventually want the same thing.

## What's in `common.sh`

**Logging.** `log_info`, `log_warn`, and `log_error` print consistently tagged, greppable output (`[*]`, `[!]`, `[x]`). Warnings and errors go to stderr, not stdout, so redirecting a run's normal output to a log file still lets problems surface on the terminal.

**`command_exists`.** Checks the current `$PATH` the same way the shell would when you actually run a command, used wherever a setup script needs to check for something that isn't managed by apt/dnf (Claude Code's npm install, for example).

**`ensure_opt_dir`.** Creates `/opt` as a shared, group-writable, setgid directory (`2775`) so later steps can `git clone` into it without needing `sudo` for every single clone, without making it world-writable the way a blunt `chmod 777` would.

**`git_clone_or_update`.** Clones a repo if it isn't already there, or does a fast-forward-only pull if it is. Used by every tool in this repo that comes from a git repo rather than a package manager, it's the backbone of Kali_Setup.sh's priv-esc and payload script trees in particular.

**`clone_terminal_customization`.** A thin, purpose-specific wrapper around `git_clone_or_update` that knows the [Terminal-Customization](https://github.com/cameronww7/Terminal-Customization) repo's URL and install path, so the setup scripts that want it available don't need to know either detail themselves.

**`add_sudo_lecture_config`.** Configures two sudo quality-of-life settings, `pwfeedback` (asterisks while typing your password) and a lecture message shown on every `sudo` call. Writes to a `sudoers.d` drop-in file rather than editing `/etc/sudoers` directly, so a mistake here can't leave sudo broken system-wide, the file gets syntax-checked with `visudo -c` and removed automatically if something's wrong with it. The lecture message text itself lives in [`sudo_lecture.txt`](sudo_lecture.txt), edit that file if you want to change what it says.

**`ensure_flatpak_flathub`.** Installs flatpak itself if it's missing, then adds the Flathub remote if it isn't already there. Called internally by `flatpak_install_if_missing`, you shouldn't normally need to call this one directly.

**`flatpak_install_if_missing`.** The fallback install path used whenever an app doesn't publish a native apt/dnf package for the distro a script is running on, Ghostty on the apt-based targets, and Discord/Slack/Spotify/Signal on Fedora are the current examples. Search any setup script for `flatpak_install_if_missing` to see exactly which apps use it and why, each call sits next to a comment or log message explaining the reason.

**`confirm_reboot_prompt`.** Offers a reboot once a setup script finishes. Worth asking for, not just a nicety, kernel/systemd updates from earlier in the run don't take effect until reboot, and the sudoers changes from `add_sudo_lecture_config` are worth confirming took effect cleanly. Set `AUTO_REBOOT=yes` in the environment before running a setup script to skip the interactive prompt and reboot automatically, useful for a non-interactive or chained run.

## `sudo_lecture.txt`

The actual lecture text `add_sudo_lecture_config` installs to `/etc/sudo_lecture.txt`. It's plain text with embedded ANSI color codes, so it renders as small colored ASCII art in the terminal on every `sudo` call. Edit this file directly if you want to change the message, no script changes needed, `add_sudo_lecture_config` just copies whatever is here.

## Adding a new helper

A few conventions to keep in mind if you're adding to this file:

- Name it after what it does, not which script uses it, `ensure_*` for idempotent setup steps, `*_install_if_missing` for install helpers, `*_or_update` for clone/sync helpers. Keeping the naming consistent is what makes it obvious at a glance whether something already exists here.
- Write a comment above it explaining not just what it does but why it's built the way it is, especially if there's a non-obvious reason (a security consideration, a quirk of the tool it wraps, why it's not using some more "obvious" approach). The setup scripts that source this file follow the same convention, a comment that only restates the function name in prose isn't pulling its weight.
- If the helper is specific to one package manager (apt vs dnf), it belongs in that script instead, not here. This file is for logic every script needs regardless of which package manager it's using.
