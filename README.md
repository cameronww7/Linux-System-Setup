# 🐧 Linux-System-Setup

My personal machine provisioning scripts. Instead of clicking through the same installs every time I set up a new box, I run one script and it handles everything: system updates, dev tools, browsers, and the apps I use every day.

![Shell](https://img.shields.io/badge/shell-bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Package Managers](https://img.shields.io/badge/package%20managers-apt%20%7C%20dnf-0091BD?style=flat-square)
![Idempotent](https://img.shields.io/badge/idempotent-yes-3EC669?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-brightgreen?style=flat-square)

## Pick your machine

| Target | What it is | Setup guide |
|---|---|---|
| 🐧 GNOME | Debian/Ubuntu-family desktop, installed with `apt` | [`Gnome_Setup/README.md`](Gnome_Setup/README.md) |
| 🎩 Fedora | Fedora GNOME desktop, installed with `dnf` | [`Fedora_Setup/README.md`](Fedora_Setup/README.md) |
| 🐉 Kali | Pentest box: recon tools, priv-esc scripts, payloads | [`Kali_Setup/README.md`](Kali_Setup/README.md) |

GNOME and Fedora install the same set of apps through their own package manager, so it doesn't matter which one you started on, the muscle memory carries over.

## What you actually get

- **One script per machine.** No clicking through app stores or copy-pasting install commands from memory.
- **Safe to re-run.** Every step checks whether it's already done before doing anything, so running the script again just catches you up instead of reinstalling everything from scratch.
- **Self-locating.** Clone this repo anywhere you want, the scripts figure out their own path at runtime.
- **Native installs where they exist.** Real apt/dnf repos for Brave, VS Code, Slack, ProtonVPN, and friends. Flatpak only steps in on Fedora, for the handful of apps that don't publish an rpm.
- **The daily-driver app set.** Discord, Slack, Zoom, VS Code, ProtonVPN, Spotify, GitHub Desktop, Brave, Signal, and Claude Code, on both desktop targets.

## How the pieces fit together

```
                          lib/common.sh
              (shared helpers, idempotency, sudo lecture)
                               |
            +------------------+------------------+
            |                  |                   |
     Gnome_Setup.sh      Fedora_Setup.sh      Kali_Setup.sh
            |                  |                   |
      apt, daily apps    dnf, daily apps    apt, pentest tools
```

All three scripts are built on the same helpers in `lib/common.sh`: idempotent installs, git clone-or-pull, the sudo lecture setup. What each one actually installs is completely different, but the underlying behavior is consistent across all three.

## Getting started

```bash
git clone https://github.com/cameronww7/Linux-System-Setup.git
cd Linux-System-Setup/<Gnome_Setup|Fedora_Setup|Kali_Setup>/
./<Gnome_Setup|Fedora_Setup|Kali_Setup>.sh   # don't run this with sudo, it calls sudo itself when it needs to
```

> **Warning**
> These scripts were rewritten and reviewed carefully, but haven't been run against a live install yet. Try the first run on a disposable VM before trusting it on a machine you care about.

## Keeping it updated

There's no separate update script to remember. Just run the same setup script again whenever you want to catch up on new packages or config changes. It'll skip anything that's already in place and only do the work that's actually new.

## Terminal customization

Shell setup (prompt, plugins, `.zshrc`) isn't part of this repo. It lives in a separate project I maintain, [Terminal-Customization](https://github.com/cameronww7/Terminal-Customization). Each script here clones that repo to `/opt/Terminal-Customization` so it's available, but doesn't configure or run anything from it. That's entirely up to Terminal-Customization to handle.

## A bit of history

This repo used to be two scripts that had drifted pretty far apart: a generic `Linux_Setup` and a `Kali_Setup` that had absorbed a separate old repo along the way. Both had picked up dead installs (Atom, a hardcoded old Go version), deprecated `apt-key` usage, and a handful of genuinely broken paths and commands. The 2026 rewrite fixed all of that, added the Fedora target, made every script idempotent, and split shell customization out into its own repo.

## License

[MIT](LICENSE). Do whatever you want with it.
