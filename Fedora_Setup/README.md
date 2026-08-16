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

Quality-of-life tools are the same list too (gedit, tree, htop, glances, most, LibreOffice, terminator, Ghostty), except for how Ghostty gets installed, it isn't actually in Fedora's official repos or RPM Fusion (despite what an earlier version of this doc said), and it isn't on Flathub at all, so it comes from a Fedora COPR instead, see [Where each app actually comes from](#where-each-app-actually-comes-from) below for why, and why that's different from `Gnome_Setup`'s answer to the same problem.

Where things actually diverge is the daily-driver apps, since not everything has an official Fedora repo:

- **Discord**, for gaming and community voice or text chat. Installed via Flatpak, see below for why.
- **Slack**, for work chat, also via Flatpak.
- **Zoom**, for video calls, installed from a direct rpm.
- **Visual Studio Code**, my everyday code editor, installed from Microsoft's official dnf repo.
- **ProtonVPN**, for a VPN connection you can trust, installed from ProtonVPN's own dnf repo.
- **Spotify**, for music, also via Flatpak.
- **Signal**, for private messaging, also via Flatpak.
- **Claude Code**, for AI-assisted coding right from the terminal.

## Where each app actually comes from

This script follows a priority order for every app it installs: an official Fedora or RPM Fusion package first, then a vendor's own official dnf repo, then a signed direct rpm, then Flatpak, and only after all of those come up empty, a Fedora COPR. Nothing in this script reaches for Snap or an unsigned/unverified binary at all.

**Official dnf/RPM Fusion:** curl, git, perl, python3, python3-pip, man-pages, libpcap-devel, the `development-tools` group, gedit, tree, htop, glances, most, LibreOffice, terminator, nodejs, npm.

**A vendor's own official dnf repo**, not Fedora's own repos, but the vendor's own signed infrastructure, still a meaningfully different (and more trustworthy) tier than an individual's unreviewed COPR:

- **Brave**, from Brave's own dnf repo.
- **Visual Studio Code**, from Microsoft's own dnf repo.
- **ProtonVPN**, from ProtonVPN's own dnf repo, bootstrapped by a signed release rpm.

**A signed rpm from a direct URL**, for vendors that don't run a repo at all, but do sign what they ship. The vendor's real public key is imported and verified first in both cases, confirmed directly with `rpm -K` that the downloaded files are genuinely signed and that these are the actual vendor keys, not just installed blind:

- **Zoom**, key from `zoom.us/linux/download/pubkey`.
- **ProtonVPN's bootstrap package** (the release rpm that adds ProtonVPN's own repo above), key from ProtonVPN's own per-Fedora-release key URL.

**Flatpak (Flathub)**, for apps with no native Fedora package at all. Checked each one's actual permission manifest via Flathub's API rather than assuming a Flatpak is automatically sandboxed:

- **Discord** doesn't publish an rpm at all. Requests `--device=all` (full device access, reasonable for a voice/video app) and unrestricted `x11` alongside `wayland`, rather than the safer wayland-with-x11-fallback pattern the other three below use.
- **Slack** doesn't offer a stable, version-independent rpm URL for Fedora. Also requests `--device=all`; worth knowing its Flatpak build is a thin wrapper around Slack's own Snap package, not a Flatpak-native build.
- **Spotify** has no official Fedora repo. The most narrowly scoped of the four, device access limited to `dri` (GPU only), filesystem grants read-only and limited to Music/Pictures.
- **Signal** has no official rpm, but the Flathub package is maintained with Signal's cooperation. Also requests `--device=all`.

None of the four request the broad `--filesystem=host` grant, real sandboxing is present in all four, just not equivalent to a locked-down default, know what's actually granted before treating "it's a Flatpak" as automatically the safe choice.

**A Fedora COPR**, the last resort, used only for **Ghostty**: it has no rpm, no RPM Fusion package, and no Flathub listing either (it reserves a Flathub app id but was never actually published there). `scottames/ghostty` was checked directly before using it: it builds on Fedora's own COPR infrastructure (not the maintainer's personal machine) from a public spec, and is signed with a COPR-issued per-project key. Still lower-trust than everything above, Fedora explicitly disclaims any quality or security review over COPR contents, but it's a real, auditable build pipeline, not an opaque binary, and it's a native dnf package once enabled, unlike the alternative (Snap, confinement `classic`, meaning no sandboxing attempted at all, and not officially supported on Fedora to begin with).

## Good to know

> **Note**
> GitHub Desktop used to be installed here from the community-maintained [`shiftkey/desktop`](https://github.com/shiftkey/desktop) rpm repo, since GitHub itself doesn't publish an official Linux build. That's gone now, the fork hasn't been updated in over a year and isn't worth carrying as a dependency, use `git` from the terminal instead (or install [GitHub's official `gh` CLI](https://cli.github.com/) separately, if you want one).

> **Note**
> ProtonVPN installs from a version-pinned `.rpm` matched to your Fedora release using `rpm -E %fedora`. The pin found here was actually stale and 404ing (confirmed directly against ProtonVPN's own repo listing), it's fixed now, but if this install step starts failing again, grab a current version from [their Linux download page](https://protonvpn.com/support/linux-vpn-tool/) and update the script.

> **Note**
> Ghostty installs from a Fedora COPR (`scottames/ghostty`), not Snap, unlike `Gnome_Setup` and `Kali_Setup`. This script doesn't touch Snap at all, Snap isn't officially supported on Fedora, and a vetted COPR outranks it in the install-priority order this script follows (official repo > vendor repo > signed direct rpm > Flatpak > COPR > Snap, never a raw unsigned binary).
