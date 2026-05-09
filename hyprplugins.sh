#!/bin/bash

# Define required dependencies
DEPENDENCIES=(cmake cpio pkg-config git gcc)

# 1. Check and install missing dependencies
echo "Checking dependencies..."
for pkg in "${DEPENDENCIES[@]}"; do
    if ! pacman -Qi "$pkg" &> /dev/null; then
        echo "Installing missing dependency: $pkg"
        sudo pacman -S --noconfirm "$pkg"
    fi
done

# 2. Update hyprpm and headers
# Note: --no-shallow ensures full history for better version matching
echo "Updating hyprpm..."
hyprpm update --no-shallow

# 3. Add the official plugins repository if not already added
echo "Adding hyprland-plugins repository..."
hyprpm add https://github.com/hyprwm/hyprland-plugins

# 4. Enable the specific plugin
echo "Enabling csgo-vulkan-fix..."
hyprpm enable csgo-vulkan-fix

# 5. List status and reload
hyprpm list
hyprpm reload

echo "Done, Hyprland plugins installed! --- --- Remember to add 'exec-once = hyprpm reload' to your hyprland.conf"
