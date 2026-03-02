#!/bin/bash
#
# WM8960 Soundcard Uninstallation Script
# For Raspberry Pi OS Trixie (Kernel 6.12+)
#

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 1>&2
   exit 1
fi

echo "======================================="
echo "WM8960 Soundcard Uninstallation Script"
echo "======================================="
echo ""

uname_r=$(uname -r)

CONFIG=/boot/config.txt
[ -f /boot/firmware/config.txt ] && CONFIG=/boot/firmware/config.txt
[ -f /boot/firmware/usercfg.txt ] && CONFIG=/boot/firmware/usercfg.txt

OVERLAYS=/boot/overlays
[ -d /boot/firmware/overlays ] && OVERLAYS=/boot/firmware/overlays

# Remove kernel modules from /etc/modules
echo "Removing module configuration from /etc/modules..."
sed -i '/^snd-soc-wm8960$/d' /etc/modules
sed -i '/^snd-soc-wm8960-soundcard$/d' /etc/modules
# Also remove old seeed-voicecard modules if present
sed -i '/^snd-soc-seeed-voicecard$/d' /etc/modules
sed -i '/^snd-soc-ac108$/d' /etc/modules

# Unload modules if loaded
echo "Unloading kernel modules..."
rmmod snd_soc_wm8960_soundcard 2>/dev/null || true
rmmod snd_soc_wm8960 2>/dev/null || true
rmmod snd_soc_seeed_voicecard 2>/dev/null || true
rmmod snd_soc_ac108 2>/dev/null || true

# Remove device tree overlays
echo "Removing device tree overlays..."
PATH=$PATH:/opt/vc/bin
dtoverlay -r wm8960-soundcard 2>/dev/null || true
dtoverlay -r seeed-2mic-voicecard 2>/dev/null || true
dtoverlay -r seeed-4mic-voicecard 2>/dev/null || true
dtoverlay -r seeed-8mic-voicecard 2>/dev/null || true

rm -f ${OVERLAYS}/wm8960-soundcard.dtbo
rm -f ${OVERLAYS}/seeed-2mic-voicecard.dtbo
rm -f ${OVERLAYS}/seeed-4mic-voicecard.dtbo
rm -f ${OVERLAYS}/seeed-8mic-voicecard.dtbo

# Remove ALSA configs
echo "Removing ALSA configuration..."
rm -rf /etc/voicecard/ || true

# Remove seeed-voicecard service if it exists
echo "Removing seeed-voicecard service..."
systemctl stop seeed-voicecard.service 2>/dev/null || true
systemctl disable seeed-voicecard.service 2>/dev/null || true
rm -f /usr/bin/seeed-voicecard
rm -f /lib/systemd/system/seeed-voicecard.service

# Remove DKMS modules
echo "Removing DKMS modules..."
dkms remove -m wm8960-soundcard -v 1.0 --all 2>/dev/null || true
rm -rf /var/lib/dkms/wm8960-soundcard
rm -rf /usr/src/wm8960-soundcard-1.0
# Also remove old seeed-voicecard DKMS if present
dkms remove -m seeed-voicecard -v 0.3 --all 2>/dev/null || true
rm -rf /var/lib/dkms/seeed-voicecard
rm -rf /usr/src/seeed-voicecard-0.3

# Remove kernel modules
echo "Removing installed kernel modules..."
rm -f /lib/modules/*/kernel/sound/soc/codecs/snd-soc-wm8960.ko
rm -f /lib/modules/*/kernel/sound/soc/bcm/snd-soc-wm8960-soundcard.ko
rm -f /lib/modules/*/updates/dkms/snd-soc-wm8960.ko
rm -f /lib/modules/*/updates/dkms/snd-soc-wm8960-soundcard.ko
# Also remove old seeed-voicecard modules
rm -f /lib/modules/*/kernel/sound/soc/codecs/snd-soc-ac108.ko
rm -f /lib/modules/*/kernel/sound/soc/bcm/snd-soc-seeed-voicecard.ko
rm -f /lib/modules/*/updates/dkms/snd-soc-ac108.ko
rm -f /lib/modules/*/updates/dkms/snd-soc-seeed-voicecard.ko

# Update module dependencies
depmod -a

# Remove overlay configuration from config file
echo "Removing overlay configuration from ${CONFIG}..."
sed -i '/^dtoverlay=wm8960-soundcard/d' $CONFIG
sed -i '/^dtoverlay=seeed-2mic-voicecard/d' $CONFIG
sed -i '/^dtoverlay=seeed-4mic-voicecard/d' $CONFIG
sed -i '/^dtoverlay=seeed-8mic-voicecard/d' $CONFIG
sed -i '/^dtoverlay=i2s-mmap/d' $CONFIG

# Note: We don't remove i2c and i2s settings as they might be used by other hardware

echo ""
echo "======================================="
echo "Uninstallation Complete!"
echo "======================================="
echo ""
echo "Please reboot your Raspberry Pi to apply all settings"
echo ""
echo "sudo reboot"
echo ""
