# Changes

## 0.1.1

- Battery: the time remaining now shows as soon as you open the battery panel (it used to wait ten seconds, or stay on
  "Estimating…"), and uses the system's own estimate when the battery does not report its power draw (#1)
- Control center: a **Custom layout** (beta) in Settings > Control center. Put its parts in your own order, switch them on and
  off, and choose from 16 tiles (new: Do not disturb, Airplane mode, Dark mode, Power mode, Screenshot, Color picker,
  Clipboard, Timer, Wallpapers, Lock) and 3 more parts (Clock, Greeting, Emblem). Classic stays the default and works as before;
  if the custom layout ever fails to load, the classic one is shown. `eroxis-reset-layout` puts everything back from a terminal.
- Wallpaper: it puts itself back if the wallpaper service restarts (it used to stay blank), and the picker lists the
  Contours wallpaper and no longer carries an old name for the first one
- Battery: the cycle count shows "—" instead of 0 when the laptop does not report it (#1)

## 0.1.0 (first public release)

- The black-and-white Eroxis Shell for Hyprland on Arch-based systems (Arch, CachyOS and others), built on the shell of Vyntaris
- Two ways to install: permanent (`./install.sh`), or next to your current setup with tapes (`./install.sh --tape`)
- Control center: choose which parts show, and how wide it is
- A new emblem, a black-and-white palette (three dark themes, one light), new wallpapers
- A settings page for every keyboard shortcut; more than five workspaces, switched by holding `SUPER` and scrolling
- A fuller About page with the system, what Eroxis uses, and a button that copies a bug report
- Readable colors in Dolphin and other KDE apps; the logo as a picture in more terminals; a compact summary for small ones
- Memory: panels load when first used and are released after a minute idle; the shell's allocator is tuned to hold less
