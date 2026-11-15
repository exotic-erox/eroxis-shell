#!/usr/bin/env bash
set -u

name="${1:-}"
call="${2:-open}"
arg="${3:-}"
case "$name" in
    settings|help|calendar) ;;
    *) echo "usage: ${0##*/} settings|help|calendar [CALL [ARG]]" >&2; exit 2 ;;
esac

dir="$(dirname "$(readlink -f "$0")")/.."
entry="$(readlink -f "$dir/$name.qml")"
unit="eroxis-app-$name"

if [ "$call" = close ]; then
    systemctl --user is-active --quiet "$unit.scope" && timeout 2 qs -p "$entry" ipc call app close >/dev/null 2>&1
    exit 0
fi

tell() { timeout 2 qs -p "$entry" ipc call app open "$call" "$arg" >/dev/null 2>&1; }
running() { systemctl --user is-active --quiet "$unit.scope"; }

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/$unit.lock"
flock -w 5 9

for _ in $(seq 100); do
    running || break
    if tell; then sleep 0.3; running && exit 0; fi
    sleep 0.1
done
EROXIS_APP_CALL="$call" EROXIS_APP_ARG="$arg" QS_DISABLE_CRASH_HANDLER=1 \
    MALLOC_CONF=background_thread:true,dirty_decay_ms:1000,muzzy_decay_ms:0 \
    exec systemd-run --user --scope --quiet --collect --unit="$unit" --slice=app.slice -- qs -p "$entry" 9>&-
