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
2. Make it executable.
   ```sh
   chmod +x Gnome_Setup.sh
   ```
3. Run the script as your normal user, not with `sudo`. It elevates internally only for the commands that need it.
   ```sh
   ./Gnome_Setup.sh
   ```
4. Let it run. It's safe to stop and re-run at any point, every step checks whether it's already done first.
5. Reboot when it asks.

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
- **Signal**, for private messaging.
- **Claude Code**, for AI-assisted coding right from the terminal.

**Quality-of-life tools.** gedit for quick edits, tree and htop and glances for a better look at your files and system load, most as a friendlier pager than less, LibreOffice for anything that needs a full office suite, and two terminal emulators, terminator from apt and Ghostty from Snap. Ghostty doesn't publish an apt package, and despite reserving a Flathub app id, was never actually published there either, so Snap is the fallback here, it's the one Linux install option Ghostty's own project says is actually built by their own CI rather than a third party. Ghostty's theme gets set to GitHub Dark, one of the themes it already ships bundled, no separate download involved.

**Terminal-Customization.** Cloned to `/opt/Terminal-Customization` so it's ready to go, but nothing from it gets configured or run automatically. See the root README for how that's wired up.

**Favorites pinned to the GNOME dash.** Brave, Ghostty, Discord, Slack, Spotify, ProtonVPN, Signal, and VS Code get pinned automatically, merged into whatever's already pinned there rather than replacing the list, so it never removes an app you've pinned yourself. Each `.desktop` ID is checked against the real installed package rather than guessed, apt, Flatpak, and Snap don't agree on how to name the same app's `.desktop` file (Ghostty's Snap build registers as `ghostty_ghostty.desktop`, not `ghostty.desktop`, for example). Only does anything if you're actually running this in a GNOME session, skips quietly otherwise.

**A `~/Dev` folder**, a plain, empty folder in your home directory for your own projects. It's separate from `/opt`, which is where this script clones its own tools, `~/Dev` is yours to fill with whatever you're working on.

**Sudo pwfeedback and a lecture message.** Because typing your password should at least show asterisks.

## Good to know

> **Note**
> GitHub Desktop used to be installed here from the community-maintained [`shiftkey/desktop`](https://github.com/shiftkey/desktop) apt repo, since GitHub itself doesn't publish an official Linux build. That's gone now, the fork hasn't been updated in over a year and isn't worth carrying as a dependency, use `git` from the terminal instead (or install [GitHub's official `gh` CLI](https://cli.github.com/) separately, if you want one).

> **Note**
> ProtonVPN installs from a version-pinned `.deb`, because ProtonVPN doesn't offer a stable "latest" URL for it. If that install step starts failing, grab a current version from [their Linux download page](https://protonvpn.com/support/linux-vpn-tool/) and update the script. That bootstrap `.deb` drops its own apt keyring silently, so the script fetches ProtonVPN's published key fresh at runtime and checks its fingerprint against what actually landed on disk before trusting the repo it configured, instead of assuming an opaque postinst script did the right thing.

> **Note**
> Discord and Zoom install from the vendor's own official `.deb`, the install path each vendor actually recommends. Neither publishes a checksum or signature for that file anywhere, checked directly, so trust for these two specifically tops out at HTTPS transport security, there's no further verification step available on either vendor's side. Flatpak builds of both exist and were checked (Flathub-signed, and Zoom's specifically checksum-pins the binary it fetches), but the official `.deb` is the preferred install here.

> **Note**
> Claude Code installs via a user-owned npm prefix (`~/.npm-global`), not `sudo npm install -g`. A sudo'd npm install runs that package's (and its dependencies') postinstall scripts as root, more privilege than an npm install needs. The PATH addition lives in an `/etc/profile.d` drop-in rather than your shell rc file, consistent with this repo's shell customization staying out of Terminal-Customization's territory.

> **Note**
> Ghostty being installed via Snap means this script installs `snapd` too, the only place in this script that touches Snap at all. That's new infrastructure beyond the usual apt/Flatpak, added specifically because it's the only Linux install option for Ghostty that Ghostty's own project describes as built by their own CI rather than a third party, every other option (a community apt script, an AppImage) carries an explicit tampering-risk warning from Ghostty's own docs.

> **Note**
> Favorites pinning (`pin_gnome_favorites` in `lib/common.sh`) only does anything if `gsettings` can actually reach a GNOME Shell session, it warns and skips rather than failing the script if you're running this over SSH or from a bare TTY before your first graphical login. Run the script again from an actual desktop session afterward if that happens and you still want the pins.

> **Note**
> Ghostty's theme only gets set the first time, `configure_ghostty_theme` in `lib/common.sh` checks for an existing `theme =` line in `~/.config/ghostty/config` first and leaves it alone if you've since picked something else by hand.

Atom, the VirtualBox guest additions, and a hardcoded Go 1.16 install used to be part of this script. They're gone now: Atom is discontinued, VirtualBox wasn't actually in use, and Go is better installed straight from apt if you ever need it.
