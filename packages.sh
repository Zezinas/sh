#!/usr/bin/env bash
set -e
trap 'echo "Error occurred on line $LINENO"; exit 1' ERR

echo "=== Starting package installation ==="

# --- CORE HELPERS ---
echo "Installing yay (AUR helper)..."
sudo pacman -Syu --noconfirm yay

# --- OFFICIAL REPO PACKAGES ---
# Core Hyprland stuff
OFFICIAL_HYPRLAND=(
    hyprland                    # Wayland compositor
    quickshell-git              # Custom shell for Hyprland

    hyprpaper                   # Wallpaper manager for Hyprland
    hypridle                    # Idle manager (suspend, lock, etc.)
    hyprlock                    # Lock screen utility
    hyprcursor                  # Cursor theme/management

    xorg-xwayland               # XWayland support for running X apps
    xdg-desktop-portal-hyprland # Flatpak & screen sharing integration

    greetd                      # Greetd display manager
    greetd-tuigreet             # Greetd display manager TUI
    uwsm                        # Universal Wayland Sesion Manager
    # libnewt                     # ??? Terminal text editor (uwsm dependency)

    mako                        # Notifications daemon
    hyprpolkitagent             # Polkit agent

    grim                        # Screenshot utility
    slurp                       # Region selection utility
    wf-recorder                 # Screen recording utility

    wl-clipboard                # Wayland clipboard utilities
    cliphist                    # Clipboard history utility
)

# Core utilities
OFFICIAL_UTILITY=(
    fastfetch                   # System info summary
    nano                        # Terminal text editor
    openssh                     # SSH client/server
    samba                       # SMB/CIFS file sharing
)

# Core utilities / applications
OFFICIAL_APPLICATIONS=(
    alacritty                   # GPU-accelerated terminal emulator
    zed                         # Modern code editor
    zen-browser-bin             # Web Browser
    dolphin                     # Graphical file manager
    # yazi
    # pcmanfm-qt
)

# Core gaming
OFFICIAL_GAMES=(
    cachyos-gaming-meta         # Gaming meta package
    cachyos-gaming-applications # Gaming applications meta package (steam, mangohud...)
    discord                     # Chat / communication app
)

# --- AUR PACKAGES ---
# Optional / AUR apps
AUR_PACKAGES=(
    vicinae-bin                 # Raycast-like launcher
)

# Install official repo packages
echo "Installing HYPRLAND packages from official repos..."
sudo pacman -S --noconfirm --needed "${OFFICIAL_HYPRLAND[@]}"

echo "Installing UTILITY packages from official repos..."
sudo pacman -S --noconfirm --needed "${OFFICIAL_UTILITY[@]}"

echo "Installing APPLICATION packages from official repos..."
sudo pacman -S --noconfirm --needed "${OFFICIAL_APPLICATIONS[@]}"

echo "Installing GAMING packages from official repos..."
sudo pacman -S --noconfirm --needed "${OFFICIAL_GAMES[@]}"

# Install AUR repo packages
echo "Installing AUR packages via yay..."
yay -S --noconfirm --needed "${AUR_PACKAGES[@]}"

echo "=== Package installation completed! ==="
