#!/usr/bin/env bash
# bash <(curl -sL zezinas.github.io/sh/sunshine.sh) --arg
#
# Usage: ./sunshine.sh [--install] [--status] [--config] [--enable] [--disable]

set -euo pipefail
trap 'echo "error on line $LINENO" >&2; exit 1' ERR

# ─── helpers ───────────────────────────────────────────────────────────────────

info()  { echo "  $*"; }
ok()    { echo "  [ok] $*"; }
err()   { echo "  [!!] $*" >&2; }
header(){ echo; echo "── $* ──"; }

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

sunshine_status() {
    if systemctl --user is-active --quiet sunshine; then
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
    header "sunshine — enable"
    info "creating headless monitor (HEADLESS-1)..."
    mmsg dispatch create_virtual_output
    info "starting sunshine..."
    systemctl --user start sunshine
    ok "sunshine running — configure at https://localhost:47990"
}

sunshine_disable() {
    header "sunshine — disable"
    info "stopping sunshine..."
    systemctl --user stop sunshine
    info "removing headless monitor (HEADLESS-1)..."
    mmsg dispatch destroy_all_virtual_output
    ok "sunshine stopped"
}

# ─── main ──────────────────────────────────────────────────────────────────────

if [[ $# -eq 0 ]]; then
    echo "usage: $0 [--install] [--status] [--config] [--enable] [--disable]" >&2
    exit 1
else
    for arg in "$@"; do
        case $arg in
            --install)  sunshine_install ;;
            --status)   sunshine_status  ;;
            --config)   sunshine_config  ;;
            --enable)   sunshine_enable  ;;
            --disable)  sunshine_disable ;;
            *) err "unknown argument: $arg"; echo "  usage: $0 [--install] [--status] [--config] [--enable] [--disable]" >&2; exit 1 ;;
        esac
    done
    echo
    echo "done."
fi
