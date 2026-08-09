# 🐧 Gnome_Setup

For a Debian or Ubuntu-family machine running GNOME. Installs dev tools, Brave, and the daily-driver apps I use, all through apt.

## Prerequisites

- A Debian/Ubuntu-family distro with apt
- `sudo` access
- An internet connection

## Getting started

1. Move into this folder.
   ```sh
   cd Gnome_Setup
   ```
2. Run the script as your normal user, not with `sudo`. It elevates internally only for the commands that need it.
   ```sh
   ./Gnome_Setup.sh
   ```
3. Let it run. It's safe to stop and re-run at any point, every step checks whether it's already done first.
4. Reboot when it asks.

## What you get

**Base dev tools.** git, perl, python3 with pip3, build-essential, manpages-dev, and libpcap-dev, the basics you need to build things or write a quick script.

**Brave.** Installed straight from Brave's own signed apt repo, so it stays current whenever you run `apt upgrade`.

**The daily-driver apps:**

- **Discord**, for gaming and community voice or text chat.
- **Slack**, for work chat.
- **Zoom**, for video calls.
- **Visual Studio Code**, my everyday code editor, installed from Microsoft's official apt repo.
- **ProtonVPN**, for a VPN connection you can trust.
- **Spotify**, for music.
- **GitHub Desktop**, a GUI for git when the terminal isn't what you want.
- **Signal**, for private messaging.
- **Claude Code**, for AI-assisted coding right from the terminal.

**Quality-of-life tools.** gedit for quick edits, tree and htop and glances for a better look at your files and system load, most as a friendlier pager than less, and LibreOffice for anything that needs a full office suite.

**Terminal-Customization.** Cloned to `/opt/Terminal-Customization` so it's ready to go, but nothing from it gets configured or run automatically. See the root README for how that's wired up.

**Sudo pwfeedback and a lecture message.** Because typing your password should at least show asterisks.

## Good to know

> **Note**
> GitHub Desktop comes from the community-maintained [`shiftkey/desktop`](https://github.com/shiftkey/desktop) apt repo, since GitHub doesn't publish an official Linux build themselves.

> **Note**
> ProtonVPN installs from a version-pinned `.deb`, because ProtonVPN doesn't offer a stable "latest" URL for it. If that install step starts failing, grab a current version from [their Linux download page](https://protonvpn.com/support/linux-vpn-tool/) and update the script.

Atom, the VirtualBox guest additions, and a hardcoded Go 1.16 install used to be part of this script. They're gone now: Atom is discontinued, VirtualBox wasn't actually in use, and Go is better installed straight from apt if you ever need it.
