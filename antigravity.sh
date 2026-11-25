#!/usr/bin/bash
set -euo pipefail

APP_DIR="@LIBDIR@/antigravity"
FLAGS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/antigravity-flags.conf"

EXTRA_FLAGS=()
if [[ -f "$FLAGS_FILE" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        EXTRA_FLAGS+=("$line")
    done < "$FLAGS_FILE"
fi

# Auto-select Wayland or X11 unless overridden in antigravity-flags.conf
exec "$APP_DIR/antigravity" --ozone-platform-hint=auto "${EXTRA_FLAGS[@]}" "$@"
