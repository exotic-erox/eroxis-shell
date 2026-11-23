#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Eroxis Shell installer: a black-and-white Hyprland + Quickshell desktop for Arch Linux.
#
#   ./install.sh                 install (or update) Eroxis Shell
#   ./install.sh --no-packages   skip the pacman step (you have the packages already)
#   ./install.sh --uninstall     remove it again, and put back what it replaced
#   ./install.sh --tape [NAME]   do NOT touch ~/.config: make a tape for tapes-v2 in ~/.tapes/NAME (default
#                                eroxis-shell), to switch between this and your current rice with `tapes insert`
#                                and `tapes eject`. The tape links back into this folder.
#   ./install.sh --from NAME     with --tape: the Quickshell config you are switching away from (as in `qs -c NAME`,
#                                e.g. myshell); inserting stops it, ejecting starts it again
#   ./install.sh --back-to CMD   with --tape: what to start when you eject (default: `qs -c NAME -n -d`)
#   ./install.sh --force         go on even if this does not look like an Arch-based system
#   ./install.sh --fetch-hook    show a system summary (full or compact, by terminal size) when a terminal opens
#   ./install.sh --help
#
# What it touches:
#   ~/.config/quickshell/eroxis   the shell
#   ~/.config/hypr                hyprland.lua + lib/   (yours is saved to ~/.config/eroxis-backup first)
#   ~/.local/share/systemd/user   the eroxis-* services (not enabled: Hyprland starts them)
#   ~/.local/share/{applications,icons}
#   /usr/lib/eroxis, /usr/share/eroxis, /usr/share/backgrounds/eroxis, /usr/local/bin/eroxis-app   (needs sudo)
#
# Your own Hyprland additions go in ~/.config/hypr/user.lua; an update never touches that file.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
SYSROOT="${EROXIS_SYSROOT:-}"          # a staging directory for the system files; for testing only
MARK="eroxis-shell"                    # written into what we install, so an update knows it is ours
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$CONFIG/eroxis-backup/$STAMP"

if [ -t 1 ]; then B=$'\033[1m'; D=$'\033[2m'; R=$'\033[0m'; else B=""; D=""; R=""; fi
say()  { printf '%s==>%s %s\n' "$B" "$R" "$*"; }
note() { printf '    %s%s%s\n' "$D" "$*" "$R"; }
warn() { printf '%s!!%s  %s\n' "$B" "$R" "$*" >&2; }
die()  { warn "$*"; exit 1; }

# --- checks ----------------------------------------------------------------------------------------------------------

preflight() {
    [ -z "$SYSROOT" ] || return 0
    local info id like pretty
    info="$( . /etc/os-release 2>/dev/null; printf '%s|%s|%s' "${ID:-}" "${ID_LIKE:-}" "${PRETTY_NAME:-}" )"
    id="${info%%|*}"; like="${info#*|}"; like="${like%%|*}"; pretty="${info##*|}"
    case " $id $like " in
        *" arch "*|*" archlinux "*) note "System: ${pretty:-$id}" ;;
        *) [ "$FORCE" -eq 1 ] || die "Eroxis Shell is for Arch-based systems (Arch, CachyOS, EndeavourOS ...); this looks like ${pretty:-another system}. Use --force to try anyway." ;;
    esac
    command -v pacman >/dev/null || [ "$FORCE" -eq 1 ] || die "pacman not found."
    if [ "$(id -u)" -ne 0 ] && ! command -v sudo >/dev/null; then die "sudo is needed to install packages and helper files."; fi
}

# Eroxis Shell's Hyprland configuration is Lua, which Hyprland reads from 0.55.
check_hyprland() {
    [ -z "$SYSROOT" ] || return 0
    local ver="" pkg
    for pkg in hyprland hyprland-git; do
        ver="$(pacman -Q "$pkg" 2>/dev/null | awk '{print $2}' | sed -E 's/^[0-9]+://; s/^([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/')"
        [ -n "$ver" ] && break
    done
    [ -n "$ver" ] || ver="$(Hyprland --version 2>/dev/null | head -n 1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1 || true)"
    if [ -z "$ver" ]; then warn "Could not tell which Hyprland you have. Eroxis Shell needs 0.55 or newer."; return 0; fi
    if [ "$(printf '%s\n%s\n' 0.55.0 "$ver" | sort -V | head -n 1)" != "0.55.0" ]; then
        warn "Your Hyprland is $ver, and Eroxis Shell needs 0.55 or newer. Update it first (sudo pacman -Syu), or the desktop will not load."
    else
        note "Hyprland $ver"
    fi
}

# --- packages --------------------------------------------------------------------------------------------------------

# Without these the desktop does not start.
REQUIRED=(
    hyprland quickshell kitty python
    pipewire pipewire-pulse wireplumber networkmanager bluez
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk polkit
    awww hypridle hyprsunset hyprpicker wl-clipboard cliphist grim slurp swappy wf-recorder
    libnotify gnome-keyring xdg-user-dirs xdg-utils power-profiles-daemon upower
    qt6ct adw-gtk-theme papirus-icon-theme libheif imagemagick librsvg
    inter-font ttf-jetbrains-mono ttf-nerd-fonts-symbols-mono noto-fonts noto-fonts-emoji
    ttf-liberation fastfetch btop ripgrep
)
# Features that quietly stay off without them.
OPTIONAL=(
    cava                       # the music visualizer
    tesseract tesseract-data-eng  # copy text from the screen
    qrencode                   # the hotspot's QR code
    networkmanager-openvpn     # OpenVPN connections
    qt6-multimedia qt6-multimedia-ffmpeg  # video wallpapers
    arch-wiki-docs             # the Arch Wiki without internet (SUPER+SHIFT+H)
    noise-suppression-for-voice  # microphone noise suppression
    wtype
    chafa                      # the logo as a picture in more terminals (foot and others)
)

aur_helper() { command -v paru >/dev/null && echo paru || { command -v yay >/dev/null && echo yay || true; }; }

install_packages() {
    command -v pacman >/dev/null || die "pacman not found. Eroxis Shell is for Arch Linux (and Arch-based systems)."
    local sudo_cmd="sudo"; [ "$(id -u)" -eq 0 ] && sudo_cmd=""
    say "Installing packages (pacman)"

    # Only what is missing. `pacman -T` counts what a package provides, so quickshell-git or hyprland-git
    # you already have satisfies quickshell or hyprland, and is left alone.
    local in_repo=() in_aur=() pkg
    for pkg in "${REQUIRED[@]}"; do
        pacman -T "$pkg" >/dev/null 2>&1 && continue
        if pacman -Si "$pkg" >/dev/null 2>&1; then in_repo+=("$pkg"); else in_aur+=("$pkg"); fi
    done
    if [ "${#in_repo[@]}" -gt 0 ]; then
        note "Installing: ${in_repo[*]}"
        $sudo_cmd pacman -S --needed --noconfirm "${in_repo[@]}"
    fi

    local opt_repo=() opt_missing=()
    for pkg in "${OPTIONAL[@]}"; do
        pacman -T "$pkg" >/dev/null 2>&1 && continue
        pacman -Si "$pkg" >/dev/null 2>&1 && opt_repo+=("$pkg") || opt_missing+=("$pkg")
    done
    # an optional package failing must not stop the install
    if [ "${#opt_repo[@]}" -gt 0 ]; then
        note "Also installing (optional): ${opt_repo[*]}"
        $sudo_cmd pacman -S --needed --noconfirm "${opt_repo[@]}" || warn "Some optional packages did not install; the features they belong to stay off."
    fi

    if [ "${#in_aur[@]}" -gt 0 ]; then
        local helper; helper="$(aur_helper)"
        if [ -n "$helper" ]; then
            say "Installing from the AUR with $helper: ${in_aur[*]}"
            "$helper" -S --needed --noconfirm "${in_aur[@]}" || die "Could not install: ${in_aur[*]}"
        else
            die "Not in the Arch repositories, and no AUR helper (paru or yay) found: ${in_aur[*]}. Install them, then run this again."
        fi
    fi
    if [ "${#opt_missing[@]}" -gt 0 ]; then note "Not found, so skipped: ${opt_missing[*]}"; fi
    return 0
}

# --- files -----------------------------------------------------------------------------------------------------------

as_root() {
    if [ -n "$SYSROOT" ] || [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi
}
sys() { printf '%s%s' "$SYSROOT" "$1"; }

# Keep whatever was there before, once, the first time we replace it.
save_once() {
    local path="$1"
    [ -e "$path" ] || return 0
    [ -e "$path/.$MARK" ] && return 0
    mkdir -p "$BACKUP"
    cp -a "$path" "$BACKUP/$(basename "$path")"
    note "Saved your $(basename "$path") in $BACKUP"
}

# The shell writes its own Qt and GTK themes. Yours, if you have them, are kept in the backup folder first: it never
# overwrites a file it did not write.
claim_generated() {
    local f
    for f in qt6ct/qt6ct.conf gtk-3.0/gtk.css gtk-4.0/gtk.css gtk-3.0/settings.ini; do
        [ -e "$CONFIG/$f" ] || continue
        grep -q "generated by quickshell" "$CONFIG/$f" && continue
        mkdir -p "$BACKUP/$(dirname "$f")"
        mv "$CONFIG/$f" "$BACKUP/$f"
        note "Moved your ~/.config/$f to $BACKUP (Eroxis writes its own)"
    done
}

install_fetch_hook() {
    say "Adding the system summary to new terminals"
    if command -v fish >/dev/null 2>&1 || [ -d "$CONFIG/fish" ]; then
        mkdir -p "$CONFIG/fish/conf.d"
        cp "$REPO/dots/fish/eroxis-fetch.fish" "$CONFIG/fish/conf.d/eroxis-fetch.fish"
        note "fish: done (~/.config/fish/conf.d/eroxis-fetch.fish)"
    fi
    note "bash or zsh: add  [ -z \"\$EROXIS_FETCHED\" ] && [ -e ~/.config/quickshell/eroxis ] && export EROXIS_FETCHED=1 && eroxis-fetch  to your rc file"
}

install_shell() {
    say "Installing the shell"
    local dest="$CONFIG/quickshell/eroxis"
    save_once "$dest"
    claim_generated
    mkdir -p "$CONFIG/quickshell"
    rm -rf "$dest"
    cp -r "$REPO/shell" "$dest"
    chmod +x "$dest"/scripts/* 2>/dev/null || true
    touch "$dest/.$MARK"
}

install_hypr() {
    say "Installing the Hyprland configuration"
    local dest="$CONFIG/hypr"
    if [ -e "$dest/hyprland.lua" ] && [ ! -e "$dest/.$MARK" ]; then
        mkdir -p "$BACKUP"
        cp -a "$dest" "$BACKUP/hypr"
        note "Saved your ~/.config/hypr in $BACKUP/hypr"
    fi
    mkdir -p "$dest"
    rm -rf "${dest:?}/lib"
    cp -r "$REPO/dots/hypr/lib" "$dest/lib"
    cp "$REPO/dots/hypr/hyprland.lua" "$dest/hyprland.lua"
    [ -e "$dest/user.lua" ] || printf -- '-- Your own Hyprland additions. Eroxis Shell never overwrites this file.\n' > "$dest/user.lua"
    touch "$dest/.$MARK"
}

install_system_files() {
    say "Installing helpers (needs sudo)"
    local lib usr bg bin icons
    lib="$(sys /usr/lib/eroxis)"; usr="$(sys /usr/share/eroxis)"; bg="$(sys /usr/share/backgrounds/eroxis)"
    bin="$(sys /usr/local/bin)"; icons="$(sys /usr/share/icons/hicolor/scalable/apps)"
    as_root install -d "$lib" "$usr/fastfetch" "$bg" "$bin" "$icons"
    as_root install -m755 "$REPO/lib/icon-theme" "$REPO/lib/vscode-theme" "$REPO/lib/kde-colors" "$REPO/lib/eroxis-fetch" "$REPO/lib/eroxis-reset-layout" "$lib/"
    as_root install -m644 "$REPO/dots/kitty.conf" "$usr/kitty.conf"
    as_root install -m644 "$REPO/assets/fastfetch-logo.png" "$usr/fastfetch/logo.png"
    as_root install -m644 "$REPO/dots/fastfetch/config.jsonc" "$usr/fastfetch/full.jsonc"
    as_root install -m644 "$REPO/dots/fastfetch/compact.jsonc" "$usr/fastfetch/compact.jsonc"
    as_root install -m644 "$REPO"/shell/assets/wallpapers/* "$bg/"
    as_root install -m644 "$REPO/assets/eroxis-logo.svg" "$icons/eroxis.svg"
    as_root ln -sf "$CONFIG/quickshell/eroxis/scripts/app.sh" "$bin/eroxis-app"
    as_root ln -sf "${lib#"$SYSROOT"}/eroxis-fetch" "$bin/eroxis-fetch"
    as_root ln -sf "${lib#"$SYSROOT"}/eroxis-reset-layout" "$bin/eroxis-reset-layout"
}

install_user_files() {
    say "Installing icons, launchers and services"
    mkdir -p "$DATA/icons" "$DATA/applications" "$DATA/systemd/user"
    rm -rf "$DATA/icons/Bibata-Modern-Ice"
    cp -r "$REPO/dots/icons/Bibata-Modern-Ice" "$DATA/icons/"
    cp "$REPO"/dots/systemd/user/* "$DATA/systemd/user/"
    if [ "$MODE" = install ]; then
        cp "$REPO"/dots/applications/*.desktop "$DATA/applications/"
        mkdir -p "$CONFIG/fastfetch"
        [ -e "$CONFIG/fastfetch/config.jsonc" ] || cp "$REPO/dots/fastfetch/config.jsonc" "$CONFIG/fastfetch/config.jsonc"
        command -v update-desktop-database >/dev/null && update-desktop-database "$DATA/applications" 2>/dev/null || true
    fi
    # the services are not enabled: the Eroxis session (started by Hyprland) pulls them in, so they never run
    # under any other desktop
    rm -f "$CONFIG"/systemd/user/eroxis-* 2>/dev/null || true
    if [ -z "$SYSROOT" ] && command -v systemctl >/dev/null; then systemctl --user daemon-reload 2>/dev/null || true; fi
}

# A tape for tapes-v2 (github.com/futurekismo-oss/tapes-v2): the folders that replace ~/.config/{quickshell,hypr,
# fastfetch} while it is inserted. They are links back into this repository, so editing the repository edits the tape.
make_tape() {
    local dir="$TAPES/$TAPE_NAME" back
    say "Making the tape $dir"
    mkdir -p "$dir/quickshell" "$dir/hypr" "$dir/fastfetch" "$dir/qt6ct" "$dir/gtk-3.0" "$dir/gtk-4.0" "$dir/kitty" "$dir/btop"
    # the shell writes its own Qt, GTK, kitty and btop themes; folders of their own keep them apart from the other rice's
    for d in qt6ct gtk-3.0 gtk-4.0 kitty btop; do [ -e "$dir/$d/.eroxis" ] || : > "$dir/$d/.eroxis"; done
    ln -sfn "$REPO/shell" "$dir/quickshell/eroxis"
    ln -sfn "$REPO/dots/hypr/hyprland.lua" "$dir/hypr/hyprland.lua"
    ln -sfn "$REPO/dots/hypr/lib" "$dir/hypr/lib"
    ln -sfn "$REPO/dots/fastfetch/config.jsonc" "$dir/fastfetch/config.jsonc"
    [ -e "$dir/hypr/user.lua" ] || printf -- '-- Your own Hyprland additions. Eroxis Shell never overwrites this file.\n' > "$dir/hypr/user.lua"
    back="${BACK_TO//\\/\\\\}"; back="${back//\"/\\\"}"
    local kill_old="" start_old=""
    [ -z "$FROM" ] || kill_old="  \"qs kill -c $FROM || true\",\n"
    [ -z "$back" ] || start_old="  \"$back\",\n"
    {
        printf '[tape]\nname = "%s"\ndesc = "Eroxis Shell: a black-and-white Hyprland + Quickshell desktop"\ndependencies = ["hyprland", "quickshell"]\n\n' "$TAPE_NAME"
        printf '[hooks]\ninsert = [\n'
        # stop the shell you are leaving (by name, and any other Quickshell shell), then start ours
        printf '%b' "$kill_old"
        printf '  "pkill -x qs || true",\n'
        printf '  "dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE",\n'
        printf '  "hyprctl reload",\n  "systemctl --user start eroxis-session.target",\n]\n\n'
        printf 'eject = [\n'
        printf '  "systemctl --user stop eroxis-shell.service eroxis-wallpaper.service eroxis-cliphist-text.service eroxis-cliphist-image.service eroxis-session.target || true",\n'
        printf '  "hyprctl reload",\n'
        printf '%b' "$start_old"
        printf ']\n'
    } > "$dir/tape.toml"
}

# --- uninstall -------------------------------------------------------------------------------------------------------

uninstall() {
    say "Removing Eroxis Shell"
    if command -v systemctl >/dev/null && [ -z "$SYSROOT" ]; then
        systemctl --user stop eroxis-shell.service eroxis-wallpaper.service eroxis-cliphist-text.service \
            eroxis-cliphist-image.service eroxis-session.target 2>/dev/null || true
    fi
    rm -f "$CONFIG"/systemd/user/eroxis-* "$DATA"/systemd/user/eroxis-* "$CONFIG/fish/conf.d/eroxis-fetch.fish"
    rm -f "$DATA"/applications/eroxis-*.desktop
    rm -rf "$DATA/icons/Bibata-Modern-Ice" "$DATA/icons/Eroxis"
    rm -rf "$CONFIG/quickshell/eroxis"
    if [ -e "$CONFIG/hypr/.$MARK" ]; then
        rm -rf "$CONFIG/hypr/lib" "$CONFIG/hypr/hyprland.lua" "$CONFIG/hypr/.$MARK"
        local last; last="$(ls -1d "$CONFIG"/eroxis-backup/*/hypr 2>/dev/null | tail -n 1 || true)"
        if [ -n "$last" ]; then
            cp -a "$last"/. "$CONFIG/hypr/"
            note "Put back your Hyprland configuration from $last"
        fi
    fi
    as_root rm -rf "$(sys /usr/lib/eroxis)" "$(sys /usr/share/eroxis)" "$(sys /usr/share/backgrounds/eroxis)" \
        "$(sys /usr/local/bin/eroxis-app)" "$(sys /usr/share/icons/hicolor/scalable/apps/eroxis.svg)"
    if [ -z "$SYSROOT" ] && command -v systemctl >/dev/null; then systemctl --user daemon-reload 2>/dev/null || true; fi
    if [ -d "$TAPES/$TAPE_NAME" ]; then note "Your tape $TAPES/$TAPE_NAME is still there: run tapes eject if it is inserted, then delete the folder."; fi
    say "Done. Packages stay installed (remove them with pacman if you like); your files in ~/.config/eroxis-backup stay too."
}

# --- main ------------------------------------------------------------------------------------------------------------

usage() { sed -n '3,26p' "$0" | sed 's/^# \{0,1\}//'; }

DO_PACKAGES=1
FETCH_HOOK=0
MODE=install
TAPES="${EROXIS_TAPES:-$HOME/.tapes}"
TAPE_NAME="eroxis-shell"
FORCE=0
FROM=""
BACK_TO=""
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --uninstall) MODE=uninstall ;;
        --no-packages) DO_PACKAGES=0 ;;
        --fetch-hook) FETCH_HOOK=1 ;;
        --force) FORCE=1 ;;
        --tape) MODE=tape; if [ -n "${2:-}" ] && [ "${2#-}" = "$2" ]; then TAPE_NAME="$2"; shift; fi ;;
        --from) [ -n "${2:-}" ] || die "--from needs the name of the shell config, e.g. --from myshell"; FROM="$2"; shift ;;
        --back-to) [ -n "${2:-}" ] || die "--back-to needs a command, e.g. --back-to 'waybar'"; BACK_TO="$2"; shift ;;
        *) usage; exit 2 ;;
    esac
    shift
done

if [ "$MODE" = uninstall ]; then uninstall; exit 0; fi
[ -n "$BACK_TO" ] || [ -z "$FROM" ] || BACK_TO="qs -c $FROM -n -d"

[ "$(id -u)" -ne 0 ] || [ -n "$SYSROOT" ] || die "Run this as your normal user, not as root (it asks for sudo when it needs it)."
[ -d "$REPO/shell" ] && [ -d "$REPO/dots" ] || die "Run this from inside the cloned eroxis-shell folder."

preflight
[ "$DO_PACKAGES" -eq 1 ] && install_packages
check_hyprland

if [ "$MODE" = tape ]; then
    install_system_files
    install_user_files
    make_tape
    [ "$FETCH_HOOK" -eq 1 ] && install_fetch_hook
    cat <<EOF

${B}The tape is ready:${R} $TAPES/$TAPE_NAME   (your ~/.config is untouched)

  tapes show $TAPE_NAME       see what it replaces and the hooks it runs (read them)
  tapes insert $TAPE_NAME     switch to Eroxis Shell now
  tapes eject                 back to your old rice${BACK_TO:+ (it stops Eroxis and runs: $BACK_TO)}

  The tape links into $REPO, so edit the shell there and it is live
  (the shell reloads by itself; \`hyprctl reload\` for the Hyprland side).
  If the Eroxis desktop looks half-started after a switch, log out and back in.
EOF
    if [ -z "$BACK_TO" ]; then
        warn "Ejecting will not start your old shell again, because I do not know what it is. Start it yourself, or make the tape again with --from NAME (a Quickshell shell, as in qs -c NAME) or --back-to 'command'."
    fi
    exit 0
fi

install_shell
install_hypr
install_system_files
install_user_files
[ "$FETCH_HOOK" -eq 1 ] && install_fetch_hook

cat <<EOF

${B}Eroxis Shell is installed.${R}

  Log out, then start Hyprland (choose "Hyprland" in your login screen, or run \`Hyprland\` from a TTY).
  The shell starts by itself. Tap SUPER to open the control center (type to search apps), SUPER+I for settings,
  SUPER+F1 lists every shortcut.

  Your own Hyprland settings go in ~/.config/hypr/user.lua.
  Update:    cd $REPO && git pull && ./install.sh
  Uninstall: ./install.sh --uninstall
EOF
