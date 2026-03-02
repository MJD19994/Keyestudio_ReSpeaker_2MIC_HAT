# WM8960 Soundcard Driver for Raspberry Pi

Kernel 6.12+ compatible drivers for [ReSpeaker 2-Mics Pi HAT](https://www.seeedstudio.com/ReSpeaker-2-Mics-Pi-HAT-p-2874.html) with WM8960 codec.

## Compatibility

This driver is compatible with:
- **Raspberry Pi OS Trixie (Kernel 6.12+)** - **NEW!**
- Raspberry Pi 3 (all models)
- Raspberry Pi 4 (all models)
- Raspberry Pi 5
- 32-bit and 64-bit Raspberry Pi OS

**Note:** For older kernel versions (< 6.12), please refer to the original seeed-voicecard repository.

## Features

- Kernel 6.12+ compatible implementation
- DKMS support for automatic rebuild on kernel updates
- Simple-audio-card based architecture
- I2C communication with WM8960 codec (address 0x1a)
- Full duplex audio (playback and capture)
- Automatic device tree overlay loading

## Installation

### Quick Installation

```bash
git clone https://github.com/MJD19994/Keyestudio_ReSpeaker_2MIC_HAT
cd Keyestudio_ReSpeaker_2MIC_HAT
sudo ./install.sh
sudo reboot
```

### What the Installation Script Does

1. Installs required packages (dkms, i2c-tools, device-tree-compiler)
2. Builds the WM8960 kernel modules using DKMS:
   - `snd-soc-wm8960` - WM8960 codec driver
   - `snd-soc-wm8960-soundcard` - Sound card driver
3. Installs the device tree overlay (`wm8960-soundcard.dtbo`)
4. Configures `/boot/config.txt` to:
   - Enable I2C interface
   - Enable I2S interface
   - Load the WM8960 soundcard overlay at boot
5. Configures kernel modules to load automatically

### Post-Installation Verification

After rebooting, verify the installation:

1. **Check I2C device detection:**
   ```bash
   sudo i2cdetect -y 1
   ```
   You should see the WM8960 at address `0x1a`.

2. **Check sound card:**
   ```bash
   aplay -l
   ```
   You should see `wm8960-soundcard` listed.

3. **Check loaded modules:**
   ```bash
   lsmod | grep wm8960
   ```
   Both `snd_soc_wm8960` and `snd_soc_wm8960_soundcard` should be loaded.

4. **Test playback:**
   ```bash
   speaker-test -t wav -c 2
   ```

5. **Test recording:**
   ```bash
   arecord -D hw:0,0 -f S16_LE -r 48000 -c 2 -d 5 test.wav
   aplay test.wav
   ```

## Troubleshooting

### Module Not Loading

If the modules don't load automatically after reboot:

```bash
sudo modprobe snd-soc-wm8960
sudo modprobe snd-soc-wm8960-soundcard
```

### Check dmesg for Errors

```bash
dmesg | grep -i wm8960
dmesg | grep -i soundcard
```

### Rebuild Modules

If you update your kernel, DKMS should automatically rebuild the modules. If not:

```bash
sudo dkms build -m wm8960-soundcard -v 1.0
sudo dkms install -m wm8960-soundcard -v 1.0
```

## Manual Build (for developers)

Build the modules manually:

```bash
make clean
make
sudo make install
```

Build the device tree overlay:

```bash
./build-dtbo.sh
```

## Uninstallation

```bash
sudo ./uninstall.sh
sudo reboot
```
## ReSpeaker Documentation

Up to date documentation for reSpeaker products can be found in [Seeed Studio Wiki](https://wiki.seeedstudio.com/ReSpeaker/)!
![](https://files.seeedstudio.com/wiki/ReSpeakerProductGuide/img/Raspberry_Pi_Mic_Array_Solutions.png)


### Coherence

Estimate the magnitude squared coherence using Welch’s method.
![4-mics-linear-array-kit coherence](https://user-images.githubusercontent.com/3901856/37277486-beb1dd96-261f-11e8-898b-84405bfc7cea.png)  
Note: 'CO 1-2' means the coherence between channel 1 and channel 2.

```bash
# How to get the coherence of the captured audio(a.wav for example).
sudo apt install python-numpy python-scipy python-matplotlib
python tools/coherence.py a.wav

# Requirement of the input audio file:
- format: WAV(Microsoft) signed 16-bit PCM
- channels: >=2
```

### uninstall seeed-voicecard
If you want to upgrade the driver , you need uninstall the driver first.

```
pi@raspberrypi:~/seeed-voicecard $ sudo ./uninstall.sh 
...
------------------------------------------------------
Please reboot your raspberry pi to apply all settings
Thank you!
------------------------------------------------------
```

Enjoy !

### Technical support

For hardware testing purposes we made a Rasperry Pi OS 5.10.17-v7l+ 32-bit image with reSpeaker drivers pre-installed, which you can download by clicking on [this link](https://files.seeedstudio.com/linux/Raspberry%20Pi%204%20reSpeaker/2021-05-07-raspios-buster-armhf-lite-respeaker.img.xz).

We provide official support for using reSpeaker with the following OS:
- 32-bit Raspberry Pi OS
- 64-bit Raspberry Pi OS

And following hardware platforms:
- Raspberry Pi 3 (all models), Raspberry Pi 4 (all models)

Anything beyond the scope of official support is considered to be community supported. Support for other OS/hardware platforms can be added, provided MOQ requirements can be met. 

If you have a technical problem when using reSpeaker with one of the officially supported platforms/OS, feel free to create an issue on Github. For general questions or suggestions, please use [Seeed forum](https://forum.seeedstudio.com/c/products/respeaker/15). 


