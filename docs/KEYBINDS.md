# Shortcuts

`SUPER` is the Windows key. Press `SUPER` + `F1` in Eroxis Shell any time to see this list on screen.
To print the list Hyprland is using right now: `hyprctl binds`.

## Open things

| Keys | What |
|------|------|
| tap `SUPER` | control center; start typing to search apps |
| `SUPER` + `Return` | terminal |
| `SUPER` + `E` | files |
| `SUPER` + `B` | browser |
| `SUPER` + `C` | code editor |
| `SUPER` + `A` | all apps |
| `SUPER` + `R` | run a command |
| `SUPER` + `SHIFT` + `E` | search files |
| `SUPER` + `.` | emoji |
| `SUPER` + `V` | clipboard history |
| `SUPER` + `T` | timer and stopwatch |
| `SUPER` + `W` | wallpapers |
| `SUPER` + `SHIFT` + `W` | random wallpaper |
| `SUPER` + `I` | settings |
| `SUPER` + `F1` (or `Help`) | all shortcuts |
| `SUPER` + `H` or `CTRL` + `SHIFT` + `Escape` | task manager |
| `SUPER` + `SHIFT` + `H` | Arch Wiki, offline (needs `arch-wiki-docs`) |
| `SUPER` + `SHIFT` + `A` | sound: outputs and inputs |
| `SUPER` + `SHIFT` + `N` | hotspot |
| `SUPER` + `SHIFT` + `C` | pick a color from the screen |
| `SUPER` + `K` | keyboard layouts (again: next) |
| `SUPER` + `Space` | next keyboard layout |
| `ALT` + `Tab` / `ALT` + `SHIFT` + `Tab` | switch windows, forwards / backwards |

## Screen and session

| Keys | What |
|------|------|
| `SUPER` + `SHIFT` + `S` or `Print` | screenshot of a region |
| `SHIFT` + `Print` | screenshot of the whole screen |
| `SUPER` + `SHIFT` + `T` | copy text from the screen |
| `SUPER` + `SHIFT` + `R` | record a region (again: stop) |
| `SUPER` + `CTRL` + `R` | record the screen |
| `SUPER` + `L` | lock |
| `SUPER` + `Escape` | power menu |
| `SUPER` + `Delete` | log out |

## Windows

| Keys | What |
|------|------|
| `SUPER` + `Q` or `ALT` + `F4` | close window |
| `SUPER` + `SHIFT` + `Q` | force quit a frozen window |
| `SUPER` + `F` | fullscreen |
| `SUPER` + `SHIFT` + `Space` | float / tile |
| `SUPER` + `P` | pin on all workspaces |
| `SUPER` + `S` | switch split direction |
| `SUPER` + `G` | group windows into tabs |
| `SUPER` + `[` / `]` | previous / next tab in a group |
| `SUPER` + arrows | move focus |
| `SUPER` + `SHIFT` + arrows | move the window |
| `SUPER` + `CTRL` + arrows | resize the window |
| `SUPER` + `=` / `-` | zoom in / out |
| `SUPER` + left mouse drag | move the window |
| `SUPER` + right mouse drag | resize the window |
| `SUPER` + `SHIFT` + left mouse drag | resize the window (touchpad) |

## Workspaces

The first five always exist. Go further and the next ones appear; empty ones go away when you leave them.

| Keys | What |
|------|------|
| hold `SUPER` and scroll | next / previous workspace, as many as you like |
| `SUPER` + `1` … `9`, `0` | go to workspace 1–9, and 10 |
| `SUPER` + `SHIFT` + `1` … `0` | move the window there |
| `SUPER` + `ALT` + `1` … `0` | send the window there, and stay |
| `SUPER` + `ALT` + `←` / `→` | previous / next workspace |
| `SUPER` + `ALT` + `↓` | an empty workspace |
| `SUPER` + `SHIFT` + `ALT` + `←` / `→` | move the window to the previous / next one |
| `` SUPER + ` `` | scratchpad |
| `` SUPER + SHIFT + ` `` | send the window to the scratchpad |

## Keys on the keyboard

Volume, microphone mute, brightness, play / pause, next and previous track, calculator, airplane mode, touchpad,
camera and display keys all work.

## Change what a shortcut opens

`SUPER` + `Return`, `E`, `B` and `C` open the terminal, file manager, browser and editor you chose in
**Settings** (`SUPER` + `I`) > **Apps**. Until you choose, the first installed one of the usual ones is used.

## Change a shortcut in Settings

**Settings** (`SUPER` + `I`) > **Shortcuts** lists every shortcut with a search box. Choose **Change** next to one, pick
the modifier keys (Super, Ctrl, Alt, Shift), then press the key. It tells you if the keys are already used by
something else, and **Save** applies the change at once. **Turn off** removes a shortcut, **Reset** brings the
original back, and **Reset all** undoes every change.

Your changes are saved in `~/.config/quickshell/keybinds.json`, so `hyprland.lua` can be updated without losing them.
The workspace-number keys, the mouse shortcuts and the media keys are not in the list; change those in `user.lua`
(below).

## Add or remove a shortcut by hand

Put your changes in **`~/.config/hypr/user.lua`**. It is read after everything else, and an update never touches it
(the other file, `hyprland.lua`, is replaced by updates). If you use tapes, it is `~/.tapes/eroxis-shell/hypr/user.lua`.

```lua
-- change what a shortcut does: remove the old one, then add yours
hl.unbind("SUPER + Return")
hl.bind("SUPER + Return", hl.dsp.exec_cmd("foot"), { description = "Terminal" })

-- add a new one
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("brave"), { description = "Brave" })

-- take one away
hl.unbind("SUPER + P")

-- a shortcut for a shell panel
hl.bind("SUPER + M", hl.dsp.global("quickshell:sound"), { description = "Sound" })
```

Things to know:

- `hl.unbind` must match the key exactly as it is written in `hyprland.lua`, capitals included: `"SUPER + Return"`
  works, `"super + return"` does not. Find the exact text with `grep -n 'hl.bind' ~/.config/hypr/hyprland.lua`.
- Keys are written `"SUPER + SHIFT + S"`: modifiers first, joined by ` + `. `hyprctl binds` shows each one as Hyprland sees it.
- Run `hyprctl reload` after a change. If `user.lua` has a mistake, a notification says where.
- More about binds, and what you can put on the right-hand side: https://wiki.hypr.land/Configuring/Basics/Binds/
