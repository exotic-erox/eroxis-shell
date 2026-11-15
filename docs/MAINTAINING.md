# Maintaining Eroxis Shell

For whoever looks after the project: how to try a build yourself, how to publish it correctly, and what the license
asks of you. (This is practical guidance, not legal advice.)

## Try a build yourself

**With tapes** (your current setup stays as it is):

```sh
cd eroxis-shell                       # the folder you unpacked or cloned; keep it, the tape links into it
./install.sh --tape --from NAME       # NAME: the Quickshell config of the shell you use now (qs -c NAME)
tapes show eroxis-shell               # read what it replaces and runs
tapes insert eroxis-shell --dry-run
tapes insert eroxis-shell             # from a terminal inside Hyprland
tapes eject                           # back to how it was
```

Every time you get a new build: `tapes eject`, replace the folder (or `git pull`), `./install.sh --tape --no-packages
--from NAME`, `tapes insert eroxis-shell`.

**Permanent install, without risking your own desktop**: make a second user and try it there.

```sh
sudo useradd -m -G wheel,video,input,audio eroxistest && sudo passwd eroxistest
```

Switch to a TTY (`Ctrl` + `Alt` + `F4`), log in as `eroxistest`, then:

```sh
git clone https://github.com/exotic-erox/eroxis-shell.git && cd eroxis-shell && ./install.sh
Hyprland
```

(The packages and helper files are system-wide, so they are installed for you too; the shell and the Hyprland
configuration belong to the test user only.) Remove the user with `sudo userdel -r eroxistest` when you are done.
A virtual machine with a fresh Arch or CachyOS install works as well, and tests the whole thing from nothing.

**Worth checking before every release:** the bar and island open and close; the control center, its settings, and the
launcher; the lock screen (have a TTY ready: `loginctl unlock-session`); Settings > Shortcuts; Settings > About;
switching workspaces by holding `SUPER` and scrolling; `./install.sh --uninstall` and a second install.

## Publish it

**1. Make the repository.** On GitHub: new repository `eroxis-shell`, public, no README or license (the repository has
them). Then, from the project folder:

```sh
git init -b main
git add .
git commit -m "Eroxis Shell 0.1.0"
git remote add origin https://github.com/exotic-erox/eroxis-shell.git
git push -u origin main
```

**2. Check what GitHub shows.** The license should be detected as GPL-3.0. Add a description, topics (`hyprland`,
`quickshell`, `arch-linux`, `cachyos`, `rice`, `dotfiles`, `wayland`) and a social preview image (`assets/banner.png`).
Turn on Issues. Take **screenshots** of the bar, the island, the control center and Settings, put them in
`docs/screenshots/`, and show two or three at the top of the README: people decide in seconds.

**3. Release it.**

```sh
git tag -a v0.1.0 -m "Eroxis Shell 0.1.0"
git push --tags
```

On GitHub: Releases > Draft a new release > choose `v0.1.0`, paste the 0.1.0 part of `CHANGELOG.md`. GitHub adds the
source archives itself. For the next versions, change `VERSION`, `services/Distro.qml` (the `version` line) and
`CHANGELOG.md` together.

**4. Tell people** where they will care: r/hyprland and r/unixporn (screenshots and a short video first), the Hyprland
and Quickshell communities, CachyOS forums. Say it is a first release, that it is for Arch-based systems with Hyprland
0.55 or newer, and how to install it next to what they have (tapes).

## The license: what to do, and what you have done

Eroxis Shell is built on the shell of Vyntaris, which is free software under the **GNU General Public License,
version 3 or any later version**. That has these consequences, all already taken care of in the repository:

| What the license asks | Where it is handled |
|-----------------------|---------------------|
| The work stays under the same license, so Eroxis Shell is GPL-3.0-or-later too | `LICENSE`, the README, `NOTICE` |
| The full license text goes with it | `LICENSE` |
| A prominent notice that you modified it, and the date | `NOTICE` |
| Keep the credit to the original | `NOTICE`, `THIRD-PARTY.md`, the README, Settings > About |
| The source of what you distribute is available | the public repository (if you ever hand out builds, keep the source next to them) |
| What you add is yours to license; here under the same GPL | the SPDX line (`SPDX-License-Identifier: GPL-3.0-or-later`) at the top of the files that are Eroxis Shell's own |
| Third-party parts keep their own licenses | `THIRD-PARTY.md`, `dots/icons/Bibata-Modern-Ice/LICENSE`, `LICENSES/Apache-2.0.txt` |

Things to keep doing:

- **Never remove** `LICENSE`, `NOTICE` or the credits. If you take in code from another project, check its license
  first: GPL-3.0 and MIT are fine; anything that forbids reuse, or says "all rights reserved", is not. Add it to
  `THIRD-PARTY.md`.
- **Contributions.** People who send code keep their copyright, and it comes in under the same GPL. You may want a
  short `CONTRIBUTING.md` saying so.
- **The name and the emblem.** The GPL covers the code. The name "Eroxis" and the emblem are yours, and you may say so
  (for example: "the name and the emblem may not be used for a different product"). Before launching, search for the
  name to be sure nobody else uses it for something similar; you cannot be sure from here.
- **Vyntaris's name and artwork are not used.** Keep it that way: no "Vyntaris" logo, wallpaper or branding. It is
  courteous (not required) to let the Vyntaris maintainers know that you build on their work.
- Hyprland, Quickshell, Papirus and the rest are installed from the distribution's packages, not shipped by you, so
  their licenses are not yours to carry.

If you plan to sell it or to put it in a company's product, ask a lawyer who knows free-software licensing.
