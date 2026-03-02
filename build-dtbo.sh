#!/bin/bash

# Script to build device tree overlay for WM8960 soundcard

set -e

DTC_FLAGS="-@ -H epapr -O dtb -o"
DTC_CMD="dtc"

echo "Building wm8960-soundcard.dtbo..."

if ! which dtc &>/dev/null; then
    echo "Error: dtc (Device Tree Compiler) not found"
    echo "Please install device-tree-compiler package"
    exit 1
fi

# Build wm8960-soundcard overlay
${DTC_CMD} ${DTC_FLAGS} wm8960-soundcard.dtbo wm8960-soundcard-overlay.dts

echo "Successfully built wm8960-soundcard.dtbo"
