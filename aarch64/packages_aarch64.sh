#!/usr/bin/env bash
set -euo pipefail
trap 'echo "Error occurred on line $LINENO"; exit 1' ERR

# === Bootstrap: pacman base + Rust (paru is Rust) ===
echo "=== Bootstrapping ALARM (aarch64) base toolchain ==="
sudo pacman -Syu --noconfirm
sudo pacman -S  --needed --noconfirm base-devel git sudo rust cargo

# === paru via AUR makepkg ===
if ! command -v paru >/dev/null; then
  WORK="$(mktemp -d)"
  git clone https://aur.archlinux.org/paru.git "$WORK/paru"
  ( cd "$WORK/paru" && makepkg -si --noconfirm )
fi

# === Official repos (ALARM aarch64) ===
OFFICIAL_WAYLAND=(
    swaybg                      # Wallpaper manager for Wayland compositor
    swayidle                    # Idle manager (suspend, lock, etc.)

    mako                        # Notifications daemon
    polkit-gnome                # Polkit agent
    xorg-xwayland               # XWayland support for running X apps
    xdg-desktop-portal          # Portal daemon (D-Bus interface)
    xdg-desktop-portal-wlr      # Mango     - Flatpak & screen sharing integration
    xdg-desktop-portal-gtk      # GTK file picker portal

    greetd                      # Greetd display manager
    greetd-tuigreet             # Greetd display manager TUI
    uwsm                        # Universal Wayland Sesion Manager

    grim                        # Screenshot utility
    slurp                       # Region selection utility
    wf-recorder                 # Screen recording utility

    wl-clipboard                # Wayland clipboard utilities
    cliphist                    # Clipboard history utility
)

OFFICIAL_UTILITY=(
    # networking
    ufw                         # Firewall
    openssh                     # SSH client/server
    samba                       # SMB/CIFS file sharing

    # system utilities
    fastfetch                   # System info summary
    nano                        # Terminal text editor
    7zip                        # Archive utility (7z/zip/tar/rar)
    git                         # Version control
    btop                        # Interactive system resource monitor
    #misc utilities
    rsync                       # File sync and backup utility
    ripgrep                     # Fast recursive text search
    duf                         # Disk usage viewer (modern df)
    pv                          # Progress indicator for pipes

    # OS applications
    mpv                         # Media Player
    swayimg                     # Image Viewer
    mpd                         # Music Player daemon
    mpc                         # Music Player CLI remote for MPD
    ncmpcpp                     # Music Player TUI client for MPD

    # file managers
    yazi                        # Terminal file manager
    nautilus                    # Graphical file manager
    sushi                       # nautilus plugin: quickview -> nautilus -q (to refresh plugins)
    gst-plugins-good            # sushi plugin codec #1
    gst-plugins-bad             # sushi plugin codec #2
    gst-plugins-ugly            # sushi plugin codec #3
    gst-libav                   # sushi plugin codec #4
)

OFFICIAL_APPLICATIONS=(
    alacritty                   # GPU-accelerated terminal emulator
    # bitwarden                   # Password manager
)

# === AUR (paru aarch64) ===
AUR_PACKAGES=(
    # system (needs build from source/flags...)
    # mangowm                     # Wayland compositor
    # quickshell-git              # Custom shell
    # vicinae-git                 # Raycast-like launcher

    # applications
    zed-bin                     # Modern code editor
    zen-browser-bin             # Web Browser
)

install_official() {
  local label=$1; shift
  if (( ${#@} == 0 )); then echo "  [skip] $label (empty)"; return; fi
  echo "  [..] Installing $label (${#} packages)..."
  sudo pacman -S --noconfirm --needed "$@"
}

echo "=== Installing official ALARM aarch64 packages ==="
install_official "Wayland stack"        "${OFFICIAL_WAYLAND[@]}"
install_official "Core utilities"       "${OFFICIAL_UTILITY[@]}"
install_official "Core applications"    "${OFFICIAL_APPLICATIONS[@]}"

install_aur() {
  echo "  [..] Installing AUR packages (${#AUR_PACKAGES[@]} packages)..."
  paru -S --noconfirm --needed "${AUR_PACKAGES[@]}"
}
install_aur


# system (needs build from source/flags...)
# mangowm                     # Wayland compositor
# quickshell-git              # Custom shell
# vicinae-git                 # Raycast-like launcher

# AUR aarch64 dependancy source compile
# scenefx0.5 (needed for mangowm)
mkdir -p ~/aur && cd ~/aur
git clone https://aur.archlinux.org/scenefx0.5.git
cd scenefx0.5
makepkg -si -A --noconfirm            # builds natively on aarch64 (C/wlroots)
cd
rm -rf ~/aur

# mangowm
paru -S --noconfirm --needed mangowm
# quickshell-git
MAKEFLAGS="-j1" paru -S --noconfirm --needed quickshell-git
# vicinae-git
CARGO_BUILD_JOBS=1 paru -S --noconfirm --needed vicinae-git


# === mimeapps (optional: guard directory) ===
echo "=== Setting default applications ==="
mkdir -p ~/.config

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

echo "=== Done. ALARM aarch64 setup complete. ==="
