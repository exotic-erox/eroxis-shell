# What Eroxis Shell is built on, and what it ships

Eroxis Shell's own files are this repository's, under the GNU General Public License, version 3 or any later version
(see `LICENSE`). Shipped with them, under their own licenses:

| What | Where | Made by | License |
|------|-------|---------|---------|
| The shell: its code, layout and design, which Eroxis Shell modifies (see `NOTICE`) | `shell/`, `dots/hypr/` | Vyntaris, github.com/vyntaris/vyntaris | GPL-3.0-or-later |
| Bibata Modern Ice (cursor theme) | `dots/icons/Bibata-Modern-Ice`, installed to `~/.local/share/icons` | Abdulkaiz Khatri (ful1e5), github.com/ful1e5/Bibata_Cursor | GPL-3.0, text in its `LICENSE` |
| Material Symbols, Rounded (the shell's icons: the ones it uses) | `shell/components/MaterialIcons.js` | Google, fonts.google.com/icons | Apache-2.0, text in `LICENSES/Apache-2.0.txt` |

The wallpapers (`shell/assets/wallpapers`) and the emblem (`assets/`) are Eroxis Shell's own, made by
`tools/make-wallpapers.py` and from the emblem file `assets/eroxis-logo.svg`.

Everything else the desktop uses (Hyprland, Quickshell, Papirus, the fonts, the apps) comes as packages from your
distribution, each with its own license in `/usr/share/licenses`.

## Thanks

Eroxis Shell is made possible by Hyprland and Quickshell, and by Vyntaris, whose shell it is built on. Thanks also
to Caelestia, whose way of keeping a shell, its configuration and an installer together was an inspiration; no
Caelestia code is included. And to the authors of tapes, which lets Eroxis Shell be tried next to another setup.
