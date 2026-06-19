#!/bin/bash

# =====================
# Default configuration
# =====================

DEFAULT_SESSION="uwsm"       # uwsm | direct
DEFAULT_COMPOSITOR="mango"   # mango | hyprland


# ===================================
# Argument parsing + Input validation
# ===================================

SESSION="$DEFAULT_SESSION"
COMPOSITOR="$DEFAULT_COMPOSITOR"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --session)
            SESSION="$2"
            shift 2
            ;;
        --compositor)
            COMPOSITOR="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

case "$SESSION" in
    uwsm|direct) ;;
    *)
        echo "Invalid session: $SESSION"
        exit 1
        ;;
esac

case "$COMPOSITOR" in
    mango|hyprland) ;;
    *)
        echo "Invalid compositor: $COMPOSITOR"
        exit 1
        ;;
esac

# =============
# Package logic
# =============

PACKAGES=(
    greetd
    greetd-tuigreet
    uwsm
)

TO_INSTALL=()
for pkg in "${PACKAGES[@]}"; do
    pacman -Q "$pkg" &>/dev/null || TO_INSTALL+=("$pkg")
done

if (( ${#TO_INSTALL[@]} > 0 )); then
    sudo pacman -S --noconfirm "${TO_INSTALL[@]}"
fi

# ============================================================
# Build launch command + Generate greetd config + Write config
# ============================================================

# Build session command
build_session_command() {
    declare -A SESSION_MAP
    SESSION_MAP["uwsm_hyprland"]="uwsm start hyprland-uwsm.desktop"
    SESSION_MAP["uwsm_mango"]="uwsm start mango.desktop"
    SESSION_MAP["direct_hyprland"]="Hyprland"
    SESSION_MAP["direct_mango"]="mango"
    echo "${SESSION_MAP[${SESSION}_${COMPOSITOR}]}"
}

# Build greetd UI configuration
SESSION_CMD="$(build_session_command)"
QS_BIN="$(command -v quickshell 2>/dev/null || true)"
CAGE_BIN="$(command -v cage 2>/dev/null || true)"
GREET_QML="$HOME/.config/quickshell/greet"
GREET_USER="${SUDO_USER:-$USER}"

if [[ -n "$QS_BIN" ]] && [[ -n "$CAGE_BIN" ]] && [[ -f "$GREET_QML/shell.qml" ]] && [[ -f "$GREET_QML/GreetSurface.qml" ]]; then
    # Primary: quickshell greeter
    mkdir -p "$GREET_QML"

    # In the quickshell branch of the script:
    echo "$GREET_USER" > "$GREET_QML/session"     # line 1: username
    echo "$SESSION_CMD" >> "$GREET_QML/session"   # line 2: launch command

    GREETER_CMD="cage -- quickshell -p $GREET_QML/shell.qml"
else
    # Fallback: tuigreet
    GREETER_CMD="tuigreet --cmd $SESSION_CMD"
fi

CONFIG_FILE="/etc/greetd/config.toml"
sudo mkdir -p "$(dirname "$CONFIG_FILE")"
sudo tee "$CONFIG_FILE" > /dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "$GREETER_CMD"
user = "$GREET_USER"
EOF

# ==============
# Enable service
# ==============

sudo systemctl enable --now greetd.service
