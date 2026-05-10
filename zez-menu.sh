#!/usr/bin/env bash
# bash <(curl -sL zezinas.github.io/sh/zez-menu.sh)

set -euo pipefail

# ─── config ────────────────────────────────────────────────────────────────────

BASE_URL=https://zezinas.github.io/sh

SCRIPT_LABELS=(
    "network"
    "packages"
    "font"
    "ddcutil"
    "fprintd"
    "greetd"
    "hypr plugins"
    "sunshine"
)
SCRIPT_FILES=(
    "network.sh"
    "packages.sh"
    "font.sh"
    "ddcutil.sh"
    "fprintd.sh"
    "greetd.sh"
    "hyprplugins.sh"
    "sunshine.sh"
)
SCRIPT_SUBS=(
    "all:|ip only:--ip|ssh only:--ssh|wol only:--wol|smb only:--smb"  # network
    ""  # packages
    "install:--install|uninstall:--uninstall"  # font
    ""  # ddcutil
    ""  # fprintd
    ""  # greetd
    ""  # hypr plugins
    "install:--install|status:--status|config:--conf|enable:--enable|disable:--disable"  # sunshine
)

# ─── helpers ───────────────────────────────────────────────────────────────────

err() { echo "  [!!] $*" >&2; }

require_fzf() {
    if ! command -v fzf &>/dev/null; then
        err "fzf not found — installing..."
        sudo pacman -S --noconfirm fzf
    fi
}

setup_alias() {
    if ! grep -q 'alias zez-menu' ~/.bashrc; then
        echo 'alias zez-menu="bash <(curl -sL zezinas.github.io/sh/zez-menu.sh)"' >> ~/.bashrc
        echo "  [ok] alias 'zez-menu' added — run: source ~/.bashrc"
    fi
}

fzf_menu() {
    local header=$1
    shift
    printf '%s\n' "$@" | fzf \
        --prompt="  setup > " \
        --height=40% \
        --layout=reverse \
        --border=rounded \
        --header="  $header  |  esc to go back" \
        --color="header:italic:dim"
}

run_script() {
    local file=$1 args=${2:-}
    echo
    echo "── running: $file ${args:+$args} ──"
    echo
    if [[ -n "$args" ]]; then
        bash <(curl -sL "$BASE_URL/$file") $args
    else
        bash <(curl -sL "$BASE_URL/$file")
    fi
    echo
    read -rp "  press enter to return to menu..." _
}

# ─── main ──────────────────────────────────────────────────────────────────────

require_fzf
setup_alias

while true; do
    # main menu
    chosen=$(fzf_menu "select a script to run" "${SCRIPT_LABELS[@]}") || break

    # find index of chosen label
    idx=-1
    for i in "${!SCRIPT_LABELS[@]}"; do
        [[ "${SCRIPT_LABELS[$i]}" == "$chosen" ]] && idx=$i && break
    done
    [[ $idx -eq -1 ]] && continue

    file="${SCRIPT_FILES[$idx]}"
    subs="${SCRIPT_SUBS[$idx]}"

    if [[ -z "$subs" ]]; then
        # no submenu — run directly
        run_script "$file"
    else
        # build submenu labels and args from "label:--args|label:--args"
        sub_labels=()
        sub_args=()
        IFS='|' read -ra entries <<< "$subs"
        for entry in "${entries[@]}"; do
            sub_labels+=("${entry%%:*}")
            sub_args+=("${entry#*:}")
        done

        sub_chosen=$(fzf_menu "$chosen" "${sub_labels[@]}") || continue

        # find matching sub entry
        for i in "${!sub_labels[@]}"; do
            if [[ "${sub_labels[$i]}" == "$sub_chosen" ]]; then
                run_script "$file" "${sub_args[$i]}"
                break
            fi
        done
    fi
done

echo "  bye."
