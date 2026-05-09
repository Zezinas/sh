#!/usr/bin/env bash
# bash <(curl -sL zezinas.github.io/sh/font.sh) [--install] [--uninstall]

set -euo pipefail
trap 'echo "error on line $LINENO" >&2; exit 1' ERR

# ─── config ────────────────────────────────────────────────────────────────────

FONTS_URL=https://github.com/Zezinas/sh/releases/download/fonts/fonts.tar.gz.enc
FONT_DEST=$HOME/.local/share/fonts

# ─── helpers ───────────────────────────────────────────────────────────────────

info()  { echo "  $*"; }
ok()    { echo "  [ok] $*"; }
err()   { echo "  [!!] $*" >&2; }
header(){ echo; echo "── $* ──"; }

# ─── sections ──────────────────────────────────────────────────────────────────

fonts_install() {
    header "fonts — install"

    read -rsp "  decryption password: " password
    echo

    info "downloading and decrypting..."
    curl -sL "$FONTS_URL" \
        | openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"$password" \
        | tar -xzf - -C /tmp/ \
        || { err "download or decryption failed — wrong password?"; exit 1; }

    info "installing..."
    mkdir -p "$FONT_DEST/SF-Pro"
    cp /tmp/fonts/SF-Pro/*.otf "$FONT_DEST/SF-Pro/"
    fc-cache -f
    rm -rf /tmp/fonts

    ok "SF Pro fonts installed"
    fc-list | grep -i "SF Pro" | awk -F: '{print "  "$1}' | sort
}

fonts_uninstall() {
    header "fonts — uninstall"

    if [[ ! -d "$FONT_DEST/SF-Pro" ]]; then
        info "SF Pro not installed, nothing to remove"
        return 0
    fi

    rm -rf "$FONT_DEST/SF-Pro"
    fc-cache -f
    ok "SF Pro fonts removed"
}

# ─── main ──────────────────────────────────────────────────────────────────────

if [[ $# -eq 0 ]]; then
    fonts_install
else
    for arg in "$@"; do
        case $arg in
            --install)   fonts_install   ;;
            --uninstall) fonts_uninstall ;;
            *) err "unknown argument: $arg"; echo "  usage: $0 [--install] [--uninstall]" >&2; exit 1 ;;
        esac
    done
fi

echo
echo "done."


# # Step 1 — archive:
# tar -czf fonts.tar.gz fonts/

# # Step 2 — encrypt:
# openssl enc -aes-256-cbc -pbkdf2 -in fonts.tar.gz -out fonts.tar.gz.enc

# # Step 3 — verify it worked before uploading:
# openssl enc -d -aes-256-cbc -pbkdf2 -in fonts.tar.gz.enc | tar -tzf -

# # Step 4 — clean up:
# rm fonts.tar.gz
