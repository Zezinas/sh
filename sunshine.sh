#!/usr/bin/env bash
# bash <(curl -sL zezinas.github.io/sh/sunshine.sh) --arg
#
# Usage: ./sunshine.sh [--install] [--uninstall] [--status] [--config] [--enable] [--disable]

set -euo pipefail
trap 'echo "error on line $LINENO" >&2; exit 1' ERR

# ─── helpers ───────────────────────────────────────────────────────────────────

info()  { echo "  $*"; }
ok()    { echo "  [ok] $*"; }
err()   { echo "  [!!] $*" >&2; }
header(){ echo; echo "── $* ──"; }
usage() { echo "usage: $0 [--install] [--uninstall] [--status] [--config] [--enable] [--disable]" >&2; }

# ─── sections ──────────────────────────────────────────────────────────────────

sunshine_install() {
    header "sunshine — install"
    info "creating pacman hook..."
    sudo mkdir -p /etc/pacman.d/hooks
    sudo tee /etc/pacman.d/hooks/sunshine-setcap.hook > /dev/null <<'EOF'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = sunshine

[Action]
Description = Setting cap_sys_admin on Sunshine binary...
When = PostTransaction
Exec = /bin/sh -c 'setcap cap_sys_admin+p $(readlink -f $(which sunshine))'
EOF
    ok "pacman hook written"
    info "installing sunshine..."
    sudo pacman -S --noconfirm sunshine
    ok "sunshine installed"

    header "sunshine — firewall"
    sudo ufw allow 47984/tcp
    sudo ufw allow 47989/tcp
    sudo ufw allow 48010/tcp
    sudo ufw allow 47998/udp
    sudo ufw allow 47999/udp
    sudo ufw allow 48000/udp
    ok "ufw: sunshine ports allowed"

    echo
    info "configure at: https://localhost:47990"
}

sunshine_uninstall() {
    header "sunshine - uninstall"

    read -r -p "  Remove Sunshine, its settings, pairing data, hook, and firewall rules? [y/N] " confirm
    [[ "$confirm" =~ ^[yY]$ ]] || { info "uninstall cancelled"; return 0; }

    info "stopping Sunshine..."
    systemctl --user disable --now app-dev.lizardbyte.app.Sunshine.service 2>/dev/null || true
    systemctl --user reset-failed app-dev.lizardbyte.app.Sunshine.service 2>/dev/null || true

    if pacman -Q sunshine &>/dev/null; then
        info "removing Sunshine package..."
        sudo pacman -Rns --noconfirm sunshine
        ok "sunshine package removed"
    else
        info "sunshine package is not installed"
    fi

    info "removing Sunshine user data..."
    rm -rf -- \
        "$HOME/.config/sunshine" \
        "$HOME/.local/share/sunshine" \
        "$HOME/.cache/sunshine" \
        "$HOME/.config/systemd/user/app-dev.lizardbyte.app.Sunshine.service.d"
    ok "Sunshine settings and pairing data removed"

    info "removing pacman hook..."
    sudo rm -f /etc/pacman.d/hooks/sunshine-setcap.hook
    ok "pacman hook removed"

    if command -v ufw &>/dev/null; then
        info "removing Sunshine firewall rules..."
        local rule
        for rule in \
            47984/tcp \
            47989/tcp \
            48010/tcp \
            47998/udp \
            47999/udp \
            48000/udp; do
            sudo ufw --force delete allow "$rule" &>/dev/null || true
        done
        ok "Sunshine firewall rules removed"
    else
        info "ufw is not installed; no firewall rules removed"
    fi

    ok "Sunshine uninstall complete"
}

sunshine_status() {
    if systemctl --user is-active --quiet app-dev.lizardbyte.app.Sunshine.service; then
        echo "true"
    else
        echo "false"
    fi
}

sunshine_config() {
    header "sunshine — config"
    info "opening https://localhost:47990 ..."
    xdg-open https://localhost:47990
}

sunshine_enable() {
    header "sunshine - enable"
    info "creating Mango headless display..."
    mmsg dispatch create_virtual_output
    info "starting Sunshine..."
    systemctl --user start app-dev.lizardbyte.app.Sunshine.service
    ok "Sunshine running on the 4K virtual display"
}

sunshine_disable() {
    header "sunshine - disable"
    info "stopping Sunshine..."
    systemctl --user stop app-dev.lizardbyte.app.Sunshine.service
    info "removing Mango headless display..."
    mmsg dispatch destroy_all_virtual_output
    ok "Sunshine stopped"
}

# ─── main ──────────────────────────────────────────────────────────────────────

if [[ $# -eq 0 ]]; then
    usage
    exit 1
elif [[ $# -eq 1 && $1 == "--status" ]]; then
    sunshine_status
else
    for arg in "$@"; do
        case $arg in
            --install)   sunshine_install   ;;
            --uninstall) sunshine_uninstall ;;
            --status)    sunshine_status    ;;
            --config)    sunshine_config    ;;
            --enable)    sunshine_enable    ;;
            --disable)   sunshine_disable   ;;
            --help|-h)   usage; exit 0       ;;
            *) err "unknown argument: $arg"; usage; exit 1 ;;
        esac
    done
    echo
    echo "done."
fi
