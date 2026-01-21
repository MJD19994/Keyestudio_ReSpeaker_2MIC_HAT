#!/bin/bash
#
# WM8960 Soundcard Installation Script
# For Raspberry Pi OS Trixie (Kernel 6.12+)
# Copyright (c) 2024
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}WM8960 Soundcard Installation Script${NC}"
echo -e "${GREEN}For Raspberry Pi OS Trixie (Kernel 6.12+)${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root (use sudo)${NC}" 1>&2
   exit 1
fi

# Detect config and overlays directories
CONFIG=/boot/config.txt
OVERLAYS=/boot/overlays
[ -f /boot/firmware/config.txt ] && CONFIG=/boot/firmware/config.txt
[ -f /boot/firmware/usercfg.txt ] && CONFIG=/boot/firmware/usercfg.txt
[ -d /boot/firmware/overlays ] && OVERLAYS=/boot/firmware/overlays

echo -e "${YELLOW}Using config file: ${CONFIG}${NC}"
echo -e "${YELLOW}Using overlays directory: ${OVERLAYS}${NC}"
echo ""

# Check for required directories
if [ ! -d "$OVERLAYS" ]; then
  echo -e "${RED}Error: $OVERLAYS not found or not a directory${NC}" 1>&2
  exit 1
fi

# Check for enough space on /boot volume
boot_line=$(df -h | grep -E '/boot|/boot/firmware' | head -n 1)
if [ "x${boot_line}" != "x" ]; then
  boot_space=$(echo $boot_line | awk '{print $4;}')
  free_space=$(echo "${boot_space%?}")
  unit="${boot_space: -1}"
  if [[ "$unit" = "K" ]]; then
    echo -e "${RED}Error: Not enough space left ($boot_space) on /boot${NC}"
    exit 1
  elif [[ "$unit" = "M" ]]; then
    if [ "$free_space" -lt "25" ]; then
      echo -e "${RED}Error: Not enough space left ($boot_space) on /boot${NC}"
      exit 1
    fi
  fi
fi

# Get kernel version
uname_r=$(uname -r)
echo -e "${GREEN}Detected kernel version: ${uname_r}${NC}"
echo ""

# Update and install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
apt-get update -y
apt-get install -y dkms git i2c-tools device-tree-compiler

# Install kernel headers
echo -e "${YELLOW}Installing kernel headers...${NC}"
if apt-get install -y raspberrypi-kernel-headers 2>/dev/null; then
    echo -e "${GREEN}Installed raspberrypi-kernel-headers${NC}"
elif apt-get install -y linux-headers-${uname_r} 2>/dev/null; then
    echo -e "${GREEN}Installed linux-headers-${uname_r}${NC}"
else
    echo -e "${YELLOW}Warning: Could not install kernel headers package${NC}"
    echo -e "${YELLOW}Checking if headers already exist...${NC}"
fi

# Verify kernel headers are available
if [ ! -d "/lib/modules/${uname_r}/build" ]; then
    echo -e "${RED}Error: Kernel headers not found at /lib/modules/${uname_r}/build${NC}"
    echo -e "${RED}Please install appropriate kernel headers for your kernel version${NC}"
    exit 1
fi

echo -e "${GREEN}Kernel headers found${NC}"
echo ""

# Build device tree overlay
echo -e "${YELLOW}Building device tree overlay...${NC}"
if [ -f "wm8960-soundcard-overlay.dts" ]; then
    dtc -@ -H epapr -O dtb -o wm8960-soundcard.dtbo wm8960-soundcard-overlay.dts
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully built wm8960-soundcard.dtbo${NC}"
    else
        echo -e "${RED}Error: Failed to build device tree overlay${NC}"
        exit 1
    fi
else
    echo -e "${RED}Error: wm8960-soundcard-overlay.dts not found${NC}"
    exit 1
fi
echo ""

# Install device tree overlay
echo -e "${YELLOW}Installing device tree overlay...${NC}"
cp -v wm8960-soundcard.dtbo $OVERLAYS/
echo -e "${GREEN}Device tree overlay installed${NC}"
echo ""

# Setup DKMS
ver="1.0"
mod="wm8960-soundcard"
marker="installed"

echo -e "${YELLOW}Setting up DKMS for kernel modules...${NC}"

# Remove old DKMS installations if they exist
if [ -e "/usr/src/${mod}-${ver}" ] || [ -e "/var/lib/dkms/${mod}/${ver}" ]; then
    echo "Removing old DKMS installation..."
    dkms remove -m ${mod} -v ${ver} --all 2>/dev/null || true
    rm -rf /usr/src/${mod}-${ver}
fi

# Also remove old seeed-voicecard if it exists
if [ -e "/usr/src/seeed-voicecard-0.3" ] || [ -e "/var/lib/dkms/seeed-voicecard/0.3" ]; then
    echo "Removing old seeed-voicecard DKMS installation..."
    dkms remove -m seeed-voicecard -v 0.3 --all 2>/dev/null || true
    rm -rf /usr/src/seeed-voicecard-0.3
fi

# Create DKMS source directory
mkdir -p /usr/src/${mod}-${ver}

# Copy only required source files for kernel 6.12+ compatible modules
echo "Copying source files..."
cp -v wm8960.c /usr/src/${mod}-${ver}/
cp -v wm8960.h /usr/src/${mod}-${ver}/
cp -v wm8960-soundcard.c /usr/src/${mod}-${ver}/
cp -v Makefile /usr/src/${mod}-${ver}/
cp -v dkms.conf /usr/src/${mod}-${ver}/

# Add module to DKMS
echo "Adding module to DKMS..."
dkms add -m ${mod} -v ${ver}

# Build module with DKMS
echo "Building modules with DKMS..."
dkms build -k ${uname_r} -m ${mod} -v ${ver}
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: DKMS build failed${NC}"
    exit 1
fi

# Install module with DKMS
echo "Installing modules with DKMS..."
dkms install --force -k ${uname_r} -m ${mod} -v ${ver}
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: DKMS install failed${NC}"
    exit 1
fi

echo -e "${GREEN}DKMS modules built and installed successfully${NC}"
echo ""

# Load modules at boot
echo -e "${YELLOW}Configuring modules to load at boot...${NC}"
grep -q "^snd-soc-wm8960$" /etc/modules || echo "snd-soc-wm8960" >> /etc/modules
grep -q "^snd-soc-wm8960-soundcard$" /etc/modules || echo "snd-soc-wm8960-soundcard" >> /etc/modules
echo -e "${GREEN}Module configuration complete${NC}"
echo ""

# Configure /boot/config.txt
echo -e "${YELLOW}Configuring ${CONFIG}...${NC}"

# Enable I2C
sed -i -e 's/^#dtparam=i2c_arm=on/dtparam=i2c_arm=on/g' $CONFIG
grep -q "^dtparam=i2c_arm=on" $CONFIG || echo "dtparam=i2c_arm=on" >> $CONFIG

# Enable I2S
grep -q "^dtparam=i2s=on" $CONFIG || echo "dtparam=i2s=on" >> $CONFIG

# Add wm8960-soundcard overlay
# Remove old seeed-2mic-voicecard overlay if present
sed -i '/^dtoverlay=seeed-2mic-voicecard/d' $CONFIG

# Add wm8960-soundcard overlay if not already present
grep -q "^dtoverlay=wm8960-soundcard" $CONFIG || echo "dtoverlay=wm8960-soundcard" >> $CONFIG

echo -e "${GREEN}Boot configuration complete${NC}"
echo ""

# Install ALSA configuration
echo -e "${YELLOW}Installing ALSA configuration...${NC}"
mkdir -p /etc/voicecard
if [ -f "wm8960_asound.state" ]; then
    cp -v wm8960_asound.state /etc/voicecard/
    echo -e "${GREEN}ALSA state file installed${NC}"
fi
echo ""

# Verify I2C tools
echo -e "${YELLOW}Verifying I2C configuration...${NC}"
if which i2cdetect &>/dev/null; then
    echo -e "${GREEN}i2c-tools installed${NC}"
else
    echo -e "${YELLOW}Warning: i2c-tools not found${NC}"
fi
echo ""

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${YELLOW}Post-Installation Instructions:${NC}"
echo ""
echo -e "1. ${GREEN}Reboot your Raspberry Pi:${NC}"
echo -e "   ${YELLOW}sudo reboot${NC}"
echo ""
echo -e "2. ${GREEN}After reboot, verify the WM8960 is detected on I2C:${NC}"
echo -e "   ${YELLOW}sudo i2cdetect -y 1${NC}"
echo -e "   (You should see device at address 0x1a)"
echo ""
echo -e "3. ${GREEN}Check if sound card is loaded:${NC}"
echo -e "   ${YELLOW}aplay -l${NC}"
echo -e "   (You should see 'wm8960-soundcard')"
echo ""
echo -e "4. ${GREEN}Check loaded kernel modules:${NC}"
echo -e "   ${YELLOW}lsmod | grep wm8960${NC}"
echo ""
echo -e "5. ${GREEN}Test audio playback:${NC}"
echo -e "   ${YELLOW}speaker-test -t wav -c 2${NC}"
echo ""
echo -e "6. ${GREEN}Test audio recording:${NC}"
echo -e "   ${YELLOW}arecord -D hw:0,0 -f S16_LE -r 48000 -c 2 test.wav${NC}"
echo ""
echo -e "${GREEN}For more information, visit:${NC}"
echo -e "${YELLOW}https://wiki.seeedstudio.com/ReSpeaker_2_Mics_Pi_HAT/${NC}"
echo ""
echo -e "${GREEN}Enjoy your WM8960 soundcard!${NC}"
echo -e "${GREEN}======================================${NC}"
