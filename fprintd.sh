#!/bin/bash
#
# install_fprintd.sh
# Automate installation of fprintd + CS9711 driver on Arch-based distros

set -e

echo
echo "=== Fingerprint Setup Script for Arch/CachyOS ==="
echo

# 1. Check if CS9711 fingerprint device is connected
if ! lsusb | grep -q "2541:0236"; then
    echo "Fingerprint device (CS9711) not found."
    echo "Please connect the device and try again."
    exit 1
fi

# 2. Install runtime dependencies
echo
echo "--- Installing fprintd and opencv..."
sudo pacman -S --needed --noconfirm fprintd opencv

# 3. Install patched libfprint from AUR
echo
echo "--- Installing libfprint-cs9711-git (patched driver) from AUR..."
sudo pacman -Rdd libfprint --noconfirm || true
yay -S --noconfirm libfprint-cs9711-rebase-git

# 4. Restart fprintd service
echo
echo "--- Restarting fprintd service..."
sudo systemctl restart fprintd

echo
echo "Service status:"
systemctl status fprintd --no-pager

# 5. Enroll fingerprint for the current user
echo
echo "=== Fingerprint Enrollment ==="
echo "You will now be asked to scan your finger for enrollment."
echo
read -p "Press Enter to begin..."
sudo fprintd-enroll -f left-index-finger $USER
echo
echo "=== Enrollment complete! ==="
echo
echo "--- Configuring PAM for sudo..."

# 1. Create backup
sudo cp /etc/pam.d/sudo /etc/pam.d/sudo.bak

# 2. Check for existing configuration to avoid duplicates
if ! grep -q "pam_fprintd.so" /etc/pam.d/sudo; then
    # Use 'sed' to insert the line after the first line (usually #%PAM-1.0)
    sudo sed -i '1a auth      sufficient    pam_fprintd.so' /etc/pam.d/sudo
    echo "Successfully added: auth sufficient pam_fprintd.so to /etc/pam.d/sudo"
else
    echo "Fingerprint configuration already exists in /etc/pam.d/sudo."
fi

echo
echo "DONE!"





# (optional??) Verify device
# lsusb | grep CS9711

# 1. Install runtime deps (IMPORTANT)
# sudo pacman -S fprintd opencv

# 2. Install patched libfprint
# yay -S libfprint-cs9711-git --rebuild

# 3. Restart service
# sudo systemctl restart fprintd

# 4. Check status
# systemctl status fprintd

# 5. Enroll   # sudo fprintd-enroll $USER
# sudo fprintd-enroll -f left-index-finger zezinas

# Configuring PAM /etc/pam.d/
# sudo nano /etc/pam.d/sudo
# insert line first line below the #%PAM-1.0 header
# auth      sufficient    pam_fprintd.so



# /etc/pam.d/
# sudo nano /etc/pam.d/sudo #enable for terminal (sudo), first line below the #%PAM-1.0 header
# auth      sufficient    pam_fprintd.so
#
# sudo nano /etc/pam.d/system-local-login # Enable for Login & Lock Screen, at the top of the auth section
# auth      sufficient    pam_fprintd.so
#
# sudo nano /etc/pam.d/polkit-1 # (Optional) Enable for Polkit (GUI auth)
# auth      sufficient    pam_fprintd.so


# fprintd-list
# fprintd-verify
# fprintd-delete
#
# sudo limine-snapper-restore
# sudo rm /var/lib/pacman/db.lck
# sudo pacman -Sy
