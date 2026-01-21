# seeed-voicecard

The drivers for [ReSpeaker Mic Hat](https://www.seeedstudio.com/ReSpeaker-2-Mics-Pi-HAT-p-2874.html), [ReSpeaker 4 Mic Array](https://www.seeedstudio.com/ReSpeaker-4-Mic-Array-for-Raspberry-Pi-p-2941.html), [6-Mics Circular Array Kit](), and [4-Mics Linear Array Kit]() for Raspberry Pi.

## Kernel Compatibility

This driver now supports:
- **Raspberry Pi OS Bookworm** (Kernel 5.x - 6.11)
- **Raspberry Pi OS Trixie** (Kernel 6.12+) - **NEW!**

The driver includes kernel 6.12+ compatible WM8960 codec drivers with improved clock (MCLK) configuration handling to address stricter requirements in newer kernel versions.

### Install seeed-voicecard
Get the seeed voice card source code and install all linux kernel drivers
```bash
git clone https://github.com/respeaker/seeed-voicecard
cd seeed-voicecard
sudo ./install.sh
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

## Troubleshooting

### Kernel 6.12+ Issues

If you encounter errors like:
```
wm8960 3-001a: failed to configure clock
wm8960 3-001a: ASoC: Failed to prepare bias: -22
arecord: set_params:1456: Unable to install hw params
```

This indicates a clock (MCLK) configuration issue. The driver has been updated to handle kernel 6.12's stricter requirements. Make sure you have:

1. Installed the latest version of this driver
2. Rebooted after installation
3. Checked that the correct device tree overlay is loaded:
   ```bash
   dtoverlay -l | grep -E "(seeed|wm8960)"
   ```

### Verifying Installation

After installation and reboot, verify your audio devices:
```bash
# List playback devices
aplay -l

# List capture devices  
arecord -l

# Test recording (2-mic hat uses hw:1,0)
arecord -D hw:1,0 -r 16000 -c 2 -f S16_LE -t wav test.wav

# Test playback
aplay -D hw:1,0 test.wav
```

### Supported Kernels

- Linux kernel 4.19 through 6.1: Fully supported
- Linux kernel 6.12+: Supported with updated drivers (this version)
- Linux kernel 6.13+: Includes compatibility checks for future kernel versions

### Technical support

For hardware testing purposes we made a Rasperry Pi OS 5.10.17-v7l+ 32-bit image with reSpeaker drivers pre-installed, which you can download by clicking on [this link](https://files.seeedstudio.com/linux/Raspberry%20Pi%204%20reSpeaker/2021-05-07-raspios-buster-armhf-lite-respeaker.img.xz).

We provide official support for using reSpeaker with the following OS:
- 32-bit Raspberry Pi OS
- 64-bit Raspberry Pi OS

And following hardware platforms:
- Raspberry Pi 3 (all models), Raspberry Pi 4 (all models)

Anything beyond the scope of official support is considered to be community supported. Support for other OS/hardware platforms can be added, provided MOQ requirements can be met. 

If you have a technical problem when using reSpeaker with one of the officially supported platforms/OS, feel free to create an issue on Github. For general questions or suggestions, please use [Seeed forum](https://forum.seeedstudio.com/c/products/respeaker/15). 


