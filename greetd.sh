#!/bin/bash

set -e

PACKAGES=(
    greetd
    greetd-tuigreet
    uwsm
)

echo "Checking installed packages..."

TO_INSTALL=()

for pkg in "${PACKAGES[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
        echo "✔ $pkg already installed"
    else
        echo "✖ $pkg not installed"
        TO_INSTALL+=("$pkg")
    fi
done

if [ ${#TO_INSTALL[@]} -gt 0 ]; then
    echo "Installing missing packages: ${TO_INSTALL[*]}"
    sudo pacman -S --noconfirm "${TO_INSTALL[@]}"
else
    echo "All packages already installed."
fi

CONFIG_FILE="/etc/greetd/config.toml"

echo "Creating greetd config..."

sudo mkdir -p /etc/greetd

sudo tee "$CONFIG_FILE" > /dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd uwsm start hyprland-uwsm.desktop"

[initial_session]
command = "uwsm start hyprland-uwsm.desktop"
user = "$USER"
EOF

echo "Enabling greetd service..."
sudo systemctl enable --now greetd.service

echo "Done! greetd is installed and configured."
