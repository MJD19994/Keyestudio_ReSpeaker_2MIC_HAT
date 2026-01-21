#
# WM8960 Soundcard Driver Makefile
# Copyright (c) 2024
# 
# Kernel 6.12+ compatible version
#

uname_r=$(shell uname -r)

# If KERNELRELEASE is defined, we've been invoked from the
# kernel build system and can use its language
ifneq ($(KERNELRELEASE),)

# Build only kernel 6.12 compatible modules
snd-soc-wm8960-objs := wm8960.o
snd-soc-wm8960-soundcard-objs := wm8960-soundcard.o

obj-m += snd-soc-wm8960.o
obj-m += snd-soc-wm8960-soundcard.o

ifdef DEBUG
ifneq ($(DEBUG),0)
	ccflags-y += -DDEBUG
endif
endif

else

DEST := /lib/modules/$(uname_r)/kernel

all:
	make -C /lib/modules/$(uname_r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(uname_r)/build M=$(PWD) clean

install:
	sudo mkdir -p ${DEST}/sound/soc/codecs/
	sudo mkdir -p ${DEST}/sound/soc/bcm/
	sudo cp snd-soc-wm8960.ko ${DEST}/sound/soc/codecs/
	sudo cp snd-soc-wm8960-soundcard.ko ${DEST}/sound/soc/bcm/
	sudo depmod -a

.PHONY: all clean install

endif

