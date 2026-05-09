#!/usr/bin/env bash
# bash <(curl -sL zezinas.github.io/sh/network.sh) --arg
# ssh-keygen -R [ipv4]
# Usage: ./network.sh [--ip] [--ssh] [--wol] [--smb]
#        No arguments runs all sections in order.

set -euo pipefail
trap 'echo "error on line $LINENO" >&2; exit 1' ERR

# ─── config ────────────────────────────────────────────────────────────────────

#IFACE=enp8s0                  # network interface (ip link to find yours)
STATIC_IP=192.168.0.222/24
GATEWAY=192.168.0.1
DNS1=1.1.1.1
DNS2=1.0.0.1
WOL_MAC=00-E0-22-80-A2-E7     # used only for reference / wakeonlan calls

# SMB shares — add/remove lines here, format: "share_name:/path/to/dir"
SMB_SHARES=(
    "Media:/mnt/media"
    "Downloads:/home/$USER/Downloads"
)

# ─── helpers ───────────────────────────────────────────────────────────────────

info()  { echo "  $*"; }
ok()    { echo "  [ok] $*"; }
err()   { echo "  [!!] $*" >&2; }
header(){ echo; echo "── $* ──"; }

get_iface() {
    ip link show | awk '/^[0-9]+: enp/ {sub(/:/, "", $2); print $2; exit}'
}

IFACE=$(get_iface)

require() {
    command -v "$1" &>/dev/null || { err "missing: $1 (install it first)"; exit 1; }
}

# ─── sections ──────────────────────────────────────────────────────────────────

setup_ip() {
    header "IP"
    require nmcli

    local con
    con=$(nmcli -t -f NAME,DEVICE con show --active | grep "$IFACE" | cut -d: -f1)

    if [[ -z "$con" ]]; then
        err "no active connection found on $IFACE"
        return 1
    fi

    info "connection: $con"
    info "setting $STATIC_IP via $GATEWAY"

    sudo nmcli con mod "$con" \
        ipv4.method manual \
        ipv4.addresses "$STATIC_IP" \
        ipv4.gateway "$GATEWAY" \
        ipv4.dns "$DNS1 $DNS2"

    sudo nmcli con up "$con" &>/dev/null
    ok "static IP applied — $(ip -4 addr show "$IFACE" | awk '/inet / {print $2}')"
}

setup_ssh() {
    header "SSH"

    sudo systemctl enable --now sshd
    systemctl is-active --quiet sshd && ok "sshd running" || { err "sshd failed to start"; return 1; }

    sudo ufw allow ssh

    info "reachable at: $(ip -4 addr show "$IFACE" | awk '/inet / {print $2}' | cut -d/ -f1)"
}

setup_wol() {
    header "WoL"
    require nmcli

    local con
    con=$(nmcli -t -f NAME,DEVICE con show --active | grep "$IFACE" | cut -d: -f1)

    if [[ -z "$con" ]]; then
        err "no active connection found on $IFACE"
        return 1
    fi

    sudo nmcli con mod "$con" 802-3-ethernet.wake-on-lan magic
    sudo nmcli con up "$con" &>/dev/null

    ok "WoL (magic packet) enabled on $con"
    info "MAC: $WOL_MAC"
    info "wake with: wakeonlan $WOL_MAC"

    # passwordless poweroff/reboot for remote control (SSH shortcuts etc.)
    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl poweroff, /usr/bin/systemctl reboot" \
        | sudo tee /etc/sudoers.d/poweroff > /dev/null
    sudo chmod 0440 /etc/sudoers.d/poweroff
    sudo visudo -cf /etc/sudoers.d/poweroff \
        && ok "sudoers: passwordless poweroff/reboot enabled" \
        || { err "sudoers syntax error — removing file"; sudo rm /etc/sudoers.d/poweroff; return 1; }
}


setup_smb() {
    header "SMB"

    # install samba if missing
    if ! command -v smbd &>/dev/null; then
        info "installing samba..."
        sudo pacman -S --noconfirm samba
    fi

    # register current user in samba password db if not already present
    if ! sudo pdbedit -L | grep -q "^$USER:"; then
        info "creating samba user: $USER (enter a samba password below)"
        sudo smbpasswd -a "$USER"
    else
        ok "samba user $USER already registered"
    fi

    # write smb.conf
    info "writing /etc/samba/smb.conf"
    local conf
    conf=$(cat <<'EOF'
[global]
    workgroup = WORKGROUP
    server string = %h
    security = user
    passdb backend = tdbsam

    # apple/macos optimizations
    vfs objects = fruit streams_xattr
    fruit:metadata = stream
    fruit:model = MacSamba
    fruit:posix_rename = yes
    fruit:veto_appledouble = no
    fruit:wipe_intentionally_left_blank_rfork = yes
    fruit:delete_empty_adfiles = yes

    # performance
    min protocol = SMB2
    socket options = TCP_NODELAY IPTOS_LOWDELAY
    read raw = yes
    write raw = yes
    strict locking = no

    log file = /var/log/samba/%m.log
    max log size = 50

EOF
)

    local has_shares=0
    for entry in "${SMB_SHARES[@]}"; do
        local name path
        name="${entry%%:*}"
        path="${entry#*:}"

        # skip if path doesn't exist
        if [[ ! -d "$path" ]]; then
            info "skipping [$name] — path not found: $path"
            continue
        fi

        has_shares=1
        conf+="[$name]
    path = $path
    browseable = yes
    read only = no
    valid users = $USER
    create mask = 0664
    directory mask = 0775

"
    done

    echo "$conf" | sudo tee /etc/samba/smb.conf > /dev/null

    sudo systemctl enable smb nmb
    sudo systemctl restart smb nmb
    systemctl is-active --quiet smb && ok "smbd running" || { err "smbd failed to start"; return 1; }

    sudo ufw allow samba

    if [[ $has_shares -eq 1 ]]; then
        info "shares:"
        for entry in "${SMB_SHARES[@]}"; do
            local name path
            name="${entry%%:*}"
            path="${entry#*:}"
            [[ -d "$path" ]] && info "  \\\\$(hostname)\\$name  ->  $path"
        done
    else
        info "no shares mounted (no valid paths found)"
    fi
}

# ─── main ──────────────────────────────────────────────────────────────────────

run_all() {
    setup_ip
    setup_ssh
    setup_wol
    setup_smb
    echo
    echo "done."
}

if [[ $# -eq 0 ]]; then
    run_all
else
    for arg in "$@"; do
        case $arg in
            --ip)   setup_ip  ;;
            --ssh)  setup_ssh ;;
            --wol)  setup_wol ;;
            --smb)  setup_smb ;;
            *) err "unknown argument: $arg"; echo "usage: $0 [--ip] [--ssh] [--wol] [--smb]" >&2; exit 1 ;;
        esac
    done
    echo
    echo "done."
fi
