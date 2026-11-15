# Eroxis Shell: a short system summary when a terminal opens (installed by `./install.sh --fetch-hook`).
# Only while Eroxis Shell is the active rice, only in an interactive shell, and once per terminal.
status is-interactive; or return
test -e ~/.config/quickshell/eroxis; or return
set -q EROXIS_FETCHED; and return
set -gx EROXIS_FETCHED 1
command -q eroxis-fetch; and eroxis-fetch
