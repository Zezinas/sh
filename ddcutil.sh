#!/usr/bin/env bash

# 1) Install ddcutil if missing
if ! command -v ddcutil &> /dev/null; then
    echo "Installing ddcutil..."
    sudo pacman -S --noconfirm ddcutil
else
    echo "ddcutil already installed"
fi

# 2) Ensure i2c-dev loads on boot
if ! grep -q "^i2c-dev" /etc/modules-load.d/i2c-dev.conf 2>/dev/null; then
    echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c-dev.conf
fi

# 3) Add current user to i2c group if not already
if ! id -nG "$USER" | grep -qw i2c; then
    sudo usermod -aG i2c "$USER"
    echo "Added $USER to i2c group"
fi

# 4) Load module immediately
sudo modprobe i2c-dev

# 5) Optional: verify ddcutil works
if ddcutil getvcp 10 &> /dev/null; then
    echo "COMPLETED ddcutil working"
else
    echo "WARNING ddcutil may not be working (check monitor / permissions)"
fi

echo "WARNING Log out and back in for i2c group changes to take effect"
