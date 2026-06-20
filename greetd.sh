#!/bin/bash

# =====================
# Default configuration
# =====================

GREET_USER="${SUDO_USER:-$USER}"
GREETER_MODE="tuigreet"     # tuigreet | quickshell
QS_GREET_QML="$HOME/.config/quickshell/greet"

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

# ==========================
# Build greetd configuration
# ==========================

case "$GREETER_MODE" in
    tuigreet)
        SESSION_DIR="/usr/local/share/wayland-sessions-uwsm"
        sudo mkdir -p "$SESSION_DIR"

        for session in mango hyprland hyprland-uwsm; do
            sudo tee "$SESSION_DIR/$session.desktop" > /dev/null << DESKTOPEOF
[Desktop Entry]
Name=${session%.*}
Comment=${session} with uwsm
Exec=uwsm start ${session}.desktop
Type=Application
DESKTOPEOF
        done

        GREETER_CMD="tuigreet --cmd 'uwsm start mango.desktop' --sessions $SESSION_DIR"
        ;;
    quickshell)
        mkdir -p "$QS_GREET_QML"
        echo "$GREET_USER" > "$QS_GREET_QML/session"
        echo "uwsm start" >> "$QS_GREET_QML/session"
        GREETER_CMD="cage -- quickshell -p $QS_GREET_QML/shell.qml"
        ;;
    *)
        echo "  [!!] Invalid GREETER_MODE: $GREETER_MODE" >&2
        exit 1
        ;;
esac

# ==========================
# Write greetd configuration
# ==========================

# --- config ---
CONFIG_FILE="/etc/greetd/config.toml"
sudo mkdir -p "$(dirname "$CONFIG_FILE")"
sudo tee "$CONFIG_FILE" > /dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "$GREETER_CMD"
user = "greeter"
EOF

# ==============
# Enable service
# ==============

sudo systemctl enable --now greetd.service
