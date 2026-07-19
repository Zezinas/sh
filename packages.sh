#!/usr/bin/env bash
set -e
trap 'echo "Error occurred on line $LINENO"; exit 1' ERR

echo "=== Starting package installation ==="

# --- CORE HELPERS ---
echo "Updating system and ensuring paru (AUR helper) is available..."
sudo pacman -Syu --noconfirm paru

# --- OFFICIAL REPO PACKAGES ---
# Default: install everything. Toggle any of these to 0 to skip.
INSTALL_HYPRLAND=1
INSTALL_MANGOWM=1
INSTALL_WAYLAND=1
INSTALL_UTILITY=1
INSTALL_APPLICATIONS=1
INSTALL_GAMES=1
INSTALL_AUR=1

# Compositor-specific packages
OFFICIAL_HYPRLAND=(
    hyprland                    # Wayland compositor
    hyprcursor                  # Hyprland cursor
    xdg-desktop-portal-hyprland # Hyprland  - Flatpak & screen sharing integration
)
OFFICIAL_MANGOWM=(
    mangowm                     # Wayland compositor
    xdg-desktop-portal-wlr      # Mango     - Flatpak & screen sharing integration
    # xdg-user-dirs               # generate default folders, commnad: xdg-user-dirs-update
)

# Shared Wayland stack (greetd, uwsm, quickshell, portals, helpers)
OFFICIAL_WAYLAND=(
    quickshell                  # Custom shell for Hyprland     [ quickshell-git ]

    swaybg                      # Wallpaper manager for Wayland compositor
    swayidle                    # Idle manager (suspend, lock, etc.)

    mako                        # Notifications daemon
    hyprpolkitagent             # Polkit agent
    xorg-xwayland               # XWayland support for running X apps
    xdg-desktop-portal          # ???

    cage                        # ??? greetd ui stuff?
    greetd                      # Greetd display manager
    greetd-tuigreet             # Greetd display manager TUI
    uwsm                        # Universal Wayland Sesion Manager

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
    ufw                         # Firewall
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
    bitwarden                   # Password manager

    mpv                         # Media Player
    swayimg                     # Image Viewer
    mpd                         # Music Player daemon
    ncmpcpp                     # Music Player MPD client

    # yazi                      # Terminal file manager
    nautilus                    # Graphical file manager
    # xdg-desktop-portal-gtk    # GTK file picker portal
    # xdg-desktop-portal-termfilechooser
)

# Core gaming
OFFICIAL_GAMES=(
    discord                     # Chat / communication app
    cachyos-gaming-meta         # Gaming meta package
    steam                       # Steam gaming platform
    mangohud                    # Mangohud - Hardware monitoring overlay
    lib32-mangohud              # Mangohud library - 32-bit hardware monitoring overlay library
    gamescope                   # lightweight display compositor by steam
)

# --- AUR PACKAGES ---
# Optional / AUR apps
AUR_PACKAGES=(
    proton-ge-custom-bin        # Proton GE custom binary --- --- --- PROTON_ENABLE_WAYLAND=1 %command%
    vicinae-bin                 # Raycast-like launcher
    # app2unit                    # uwsm faster app launch using bash
)


install_official() {
    local label=$1; shift
    local -n pkgs=$1                 # nameref: indirect array

    if (( ${#pkgs[@]} == 0 )); then
        echo "  [skip] $label (no packages)"
        return
    fi

    echo "  [..] Installing $label (${#pkgs[@]} packages)..."
    sudo pacman -S --noconfirm --needed "${pkgs[@]}"
}

declare -A SECTIONS=(
    ["Hyprland"]="INSTALL_HYPRLAND:OFFICIAL_HYPRLAND"
    ["MangoWM"]="INSTALL_MANGOWM:OFFICIAL_MANGOWM"
    ["Wayland stack"]="INSTALL_WAYLAND:OFFICIAL_WAYLAND"
    ["Utilities"]="INSTALL_UTILITY:OFFICIAL_UTILITY"
    ["Applications"]="INSTALL_APPLICATIONS:OFFICIAL_APPLICATIONS"
    ["Games"]="INSTALL_GAMES:OFFICIAL_GAMES"
)

for label in "${!SECTIONS[@]}"; do
    IFS=':' read -r flag array <<< "${SECTIONS[$label]}"
    if (( flag )); then
        install_official "$label" "$array"
    else
        echo "  [skip] $label (disabled)"
    fi
done

if (( INSTALL_AUR )); then
    if (( ${#AUR_PACKAGES[@]} )); then
        echo "  [..] Installing AUR packages (${#AUR_PACKAGES[@]})..."
        paru -S --noconfirm --needed "${AUR_PACKAGES[@]}"
    fi
fi

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

# A.** `systemctl --user enable --now xdg-desktop-portal.service` (clean, persistent)
# B.** Add `exec-once = /usr/lib/xdg-desktop-portal -r` to MangoWM's config (lives with compositor config)





#####  ---------------------------------------- ######

# | **Media Player** | `mpv` + uosc + thumfast |
# | **Image Viewer** | `swayimg` |
# | **Music Player** | `mpd` + `ncmpcpp` | +[ `MPDroid` (Android) or `MaximumMPD` (iOS) ] +[ `Euphonica` (client)]
