# 🎩 Fedora_Setup

For a Fedora machine running GNOME. It mirrors `Gnome_Setup/` app for app, just through dnf instead of apt. If you want the reasoning behind what's installed, that folder's README has the full rundown.

## Prerequisites

- Fedora with dnf
- `sudo` access
- An internet connection

## Getting started

1. Move into this folder.
   ```sh
   cd Fedora_Setup
   ```
2. Run the script as your normal user, not with `sudo`. It elevates internally only for the commands that need it.
   ```sh
   ./Fedora_Setup.sh
   ```
3. Let it run. It's safe to stop and re-run at any point, every step checks whether it's already done first.
4. Reboot when it asks.

## What you get

This mirrors [`Gnome_Setup`](../Gnome_Setup/README.md#what-you-get) almost exactly, just through dnf instead of apt. The dev tools, Terminal-Customization clone, `~/Dev` folder, and sudo message are the same idea, only the package names change: the `Development Tools` group instead of `build-essential`, `man-pages` instead of `manpages-dev`, `libpcap-devel` instead of `libpcap-dev`. Brave installs from Brave's own official dnf repo instead of an apt one, but same browser, same deal.

Quality-of-life tools are the same list too (gedit, tree, htop, glances, most, LibreOffice, terminator), with one difference worth calling out: Ghostty installs natively from dnf here, since Fedora carries it in its official repos, unlike Gnome_Setup where it has to fall back to Flatpak.

Where things actually diverge is the daily-driver apps, since not everything has an official Fedora repo:

- **Discord**, for gaming and community voice or text chat. Installed via Flatpak, see below for why.
- **Slack**, for work chat, also via Flatpak.
- **Zoom**, for video calls, installed from a direct rpm.
- **Visual Studio Code**, my everyday code editor, installed from Microsoft's official dnf repo.
- **ProtonVPN**, for a VPN connection you can trust, installed from ProtonVPN's own dnf repo.
- **Spotify**, for music, also via Flatpak.
- **Signal**, for private messaging, also via Flatpak.
- **Claude Code**, for AI-assisted coding right from the terminal.

## Why some apps come from Flatpak

A few of these apps don't have an official Fedora or rpm repo, so they're installed from Flathub instead of natively:

- **Discord** doesn't publish an rpm at all.
- **Slack** doesn't offer a stable, version-independent rpm URL for Fedora.
- **Spotify** has no official Fedora repo.
- **Signal** has no official rpm, but the Flathub package is maintained with Signal's cooperation, so it's a solid substitute.

Everything else (Brave, VS Code, Zoom, ProtonVPN) installs natively from a dnf repo or a direct `.rpm`.

## Good to know

> **Note**
> GitHub Desktop used to be installed here from the community-maintained [`shiftkey/desktop`](https://github.com/shiftkey/desktop) rpm repo, since GitHub itself doesn't publish an official Linux build. That's gone now, the fork hasn't been updated in over a year and isn't worth carrying as a dependency, use `git` from the terminal instead (or install [GitHub's official `gh` CLI](https://cli.github.com/) separately, if you want one).

> **Note**
> ProtonVPN installs from a version-pinned `.rpm` matched to your Fedora release using `rpm -E %fedora`. If that install step starts failing, grab a current version from [their Linux download page](https://protonvpn.com/support/linux-vpn-tool/) and update the script.
