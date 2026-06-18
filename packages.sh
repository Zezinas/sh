#!/usr/bin/env bash
set -e
trap 'echo "Error occurred on line $LINENO"; exit 1' ERR

echo "=== Starting package installation ==="

# --- CORE HELPERS ---
echo "Updating system and ensuring paru (AUR helper) is available..."
sudo pacman -Syu --noconfirm paru

# --- OFFICIAL REPO PACKAGES ---
# Core Hyprland stuff
OFFICIAL_HYPRLAND=(
    mangowm                     # Wayland compositor
    quickshell                  # Custom shell for Hyprland     [ quickshell-git ]

    swaybg                      # Wallpaper manager for Wayland compositor
    swayidle                    # Idle manager (suspend, lock, etc.)

    xorg-xwayland               # XWayland support for running X apps
    xdg-desktop-portal-wlr      # Flatpak & screen sharing integration

    greetd                      # Greetd display manager
    greetd-tuigreet             # Greetd display manager TUI
    uwsm                        # Universal Wayland Sesion Manager

    mako                        # Notifications daemon
    mate-polkit                 # Polkit agent

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
    7zip                        # Archive utility (7z/zip/tar/rar)
    openssh                     # SSH client/server
    samba                       # SMB/CIFS file sharing

    git                         # Version control
    rsync                       # File sync and backup utility
    wget                        # Command-line file downloader
    ripgrep                     # Fast recursive text search
    btop                        # Interactive system resource monitor
    nano-syntax-highlighting    # Syntax highlighting for nano
    duf                         # Disk usage viewer (modern df)
    pv                          # Progress indicator for pipes
)

# Core utilities / applications
OFFICIAL_APPLICATIONS=(
    alacritty                   # GPU-accelerated terminal emulator
    zed                         # Modern code editor
    zen-browser-bin             # Web Browser
    # yazi                      # Terminal file manager

    dolphin                     # Graphical file manager
    ark                         # GUI Archive manager
    # xdg-desktop-portal-gtk      # GTK file picker portal
    # xdg-desktop-portal-termfilechooser
)

# Core gaming
OFFICIAL_GAMES=(
    discord                     # Chat / communication app
    cachyos-gaming-meta         # Gaming meta package
    steam                       # Steam gaming platform
    mangohud                    # Mangohud - Hardware monitoring overlay
    lib32-mangohud              # Mangohud library - 32-bit hardware monitoring overlay library
    # gamescope                 # lightweight display compositor by steam
)

# --- AUR PACKAGES ---
# Optional / AUR apps
AUR_PACKAGES=(
    vicinae-bin                 # Raycast-like launcher
    proton-ge-custom-bin        # Proton GE custom binary --- --- --- PROTON_ENABLE_WAYLAND=1 %command%
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
echo "Installing AUR packages via paru..."
paru -S --noconfirm --needed "${AUR_PACKAGES[@]}"

echo "=== Package installation completed! ==="


echo "=== Setting default applications ... ==="

cat > ~/.config/mimeapps.list << 'EOF'
[Default Applications]
# Browser stuff
x-scheme-handler/http=zen-browser.desktop
x-scheme-handler/https=zen-browser.desktop

# Development & Text (Zed)
text/plain=dev.zed.Zed.desktop
application/json=dev.zed.Zed.desktop
application/javascript=dev.zed.Zed.desktop
text/javascript=dev.zed.Zed.desktop
text/html=dev.zed.Zed.desktop
application/xhtml+xml=dev.zed.Zed.desktop
text/x-python=dev.zed.Zed.desktop
text/x-shellscript=dev.zed.Zed.desktop
text/markdown=dev.zed.Zed.desktop
application/xml=dev.zed.Zed.desktop
text/xml=dev.zed.Zed.desktop
text/css=dev.zed.Zed.desktop

# Broad fallbacks
application/x-yaml=dev.zed.Zed.desktop
application/toml=dev.zed.Zed.desktop
EOF

echo "=== Default application setup completed! ==="


# echo "=== Removing useless packages... ==="
# sudo pacman -Rdd --noconfirm xdg-desktop-portal-gtk 2>/dev/null || true
# echo "=== DONE. DONE. DONE. DONE. DONE. ==="
