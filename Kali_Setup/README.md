# 🐉 Kali_Setup

For a Kali Linux pentest box. This one is focused entirely on tooling: recon and enumeration tools, a privilege-escalation script tree, and payload scripts. It doesn't install any desktop productivity apps like Discord or Slack, that's what `Gnome_Setup/` and `Fedora_Setup/` are for. It also doesn't touch zsh or shell configuration at all. That's handled by a separate project I maintain, [Terminal-Customization](https://github.com/cameronww7/Terminal-Customization), which this script clones but doesn't configure or run.

## Prerequisites

- Kali Linux
- `sudo` access
- An internet connection

## Getting started

1. Move into this folder.
   ```sh
   cd Kali_Setup
   ```
2. Run the script as your normal user, not with `sudo`. It elevates internally only for the commands that need it.
   ```sh
   ./Kali_Setup.sh
   ```
3. Let it run. It's safe to stop and re-run at any point: existing git clones get pulled instead of re-cloned, existing packages get skipped, and nothing gets duplicated.
4. Reboot when it asks.

## What you get

**Brave.** Installed from Brave's own signed apt repo, so it stays current whenever you run `apt upgrade`.

**LibreOffice**, for writing up reports without switching to another machine.

**Build and dev toolchain.** git, python3 with pip3, build-essential, the libffi and libssl dev headers, mingw-w64 for cross-compiling to Windows, a JDK, and Go, since a handful of the tools below get built from source rather than installed as packages.

**Fonts.** fonts-powerline, fonts-hack, fonts-font-awesome, and fonts-powerlinesymbols, so your prompt renders its glyphs correctly once Terminal-Customization sets one up.

**Editors.** VS Code and gedit.

**System and quality-of-life tools.** tree, htop, glances, and most for a better look at what's running, plus ssh, rdesktop, freerdp-x11, ansible, autojump, and acpi for the remote-access conveniences a pentest box tends to need. Two terminal emulators come along too, terminator from apt and Ghostty from Snap. Ghostty doesn't publish an apt package, and despite reserving a Flathub app id, was never actually published there either, so Snap is the fallback here, it's the one Linux install option Ghostty's own project says is actually built by their own CI rather than a third party.

**Recon and enumeration tools.** gobuster, sslscan, nikto, joomscan, wpscan, smbmap, enum4linux, dnsrecon, odat, ffuf, nbtscan, nmap, onesixtyone, oscanner, smbclient, snmp, sipvicious, tnscmd10g, whatweb, smtp-user-enum, nishang, finalrecon, feroxbuster, redis-tools, wkhtmltopdf, crunch, nmapAutomator, naabu, and AutoRecon, basically everything you'd reach for during the recon phase of an engagement.

**Exploitation tools.** searchsploit and exploitdb, impacket (both the apt `impacket-scripts` package and the pip library, they're not duplicates of each other, one's the CLI tools and the other's what you `import` in your own scripts), pwntools, and CyberChef.

**Python libraries for scripting.** termcolor, badchars, requests, dnspython, psutil, and xlrd (that last one is specifically a Windows-Exploit-Suggester dependency).

**A privilege-escalation script tree**, cloned under `/opt/__PRIV_ESC/`: linPEAS/winPEAS, LinEnum, linux-exploit-suggester, Watson, Sherlock, PowerSploit, SharpUp, Seatbelt, and about 15 more Windows and Linux priv-esc references, organized into `_LINUX` and `_WINDOWS` subfolders.

**Payload and recon scripts**, cloned under `/opt/_Payload_Scripts/`: PayloadsAllTheThings, msfpc, shellerator, sumrecon, pwncat, gimmeSH, assetfinder, and SecLists. SecLists also feeds the generated `mega-dirbuster.txt` wordlist and the UTF-8-converted `rockyou-UTF8.txt`, so you get clean versions of both without touching them by hand.

**A `~/HACKING` working directory**, created and ready to use as scratch space for whatever engagement you're working on, plus a separate `~/Dev` folder for your own scripts and projects that aren't tied to a specific engagement.

**Sudo pwfeedback and a lecture message**, since you'll be typing your password after nearly every other command on a box like this.

## Good to know

> **Note**
> linPEAS and winPEAS always download from GitHub's `/releases/latest/` redirect instead of a version tag pinned in the script, so they stay current on every run without needing an edit.

> **Note**
> SecLists is installed once through `git clone` and kept current on re-runs. There used to be a second, duplicate copy installed through apt too, that's gone now.

> **Note**
> Ghostty being installed via Snap means this script installs `snapd` too, the only place in this script that touches Snap at all. That's new infrastructure beyond the usual apt, added specifically because it's the only Linux install option for Ghostty that Ghostty's own project describes as built by their own CI rather than a third party, every other option (a community apt script, an AppImage) carries an explicit tampering-risk warning from Ghostty's own docs.
