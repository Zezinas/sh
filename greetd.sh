#!/bin/bash
set -e

# =====================
# Package logic
# =====================

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
# Session & greetd setup
# ==========================

SESSION_DIR="/usr/local/share/wayland-sessions-uwsm"
sudo mkdir -p "$SESSION_DIR"

sudo tee "$SESSION_DIR/mango.desktop" > /dev/null << DESKTOPEOF
[Desktop Entry]
Name=mango
Comment=mangowm with uwsm
Exec=uwsm start mango.desktop
Type=Application
DESKTOPEOF

sudo mkdir -p /var/cache/tuigreet
sudo chown greeter:greeter /var/cache/tuigreet

GREETER_CMD="tuigreet --cmd 'uwsm start mango.desktop' --sessions $SESSION_DIR --remember --user-menu"

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
