#!/usr/bin/env bash

function ErrorMessage() {
    echo -e "\033[31m$1\033[37m"
}

function SuccessMessage() {
    echo -e "\033[32m$1\033[37m"
}

function WarningMessage() {
    echo -e "\033[33m$1\033[37m"
}

function StdMessage() {
    echo -e "\033[37m$1\033[37m"
}

mkdir -p ubuntukylin-build;

cd ubuntukylin-build;

BUILD_DIR=$(pwd)

mkdir -p boot

StdMessage "Checkout raspberrypi firmware source"
# Obtain boot firmware except those 32-bit stuffs (plus those debug info and VideoCore)
git clone --depth 1 -b stable https://github.com/raspberrypi/firmware.git
cp -r firmware/boot/* $$BUILD_DIR/boot
rm $BUILD_DIR/boot/*.dtb
rm $BUILD_DIR/boot/*kernel*
rm -rf firmware

# Obtain official firmware from Linux kernel org
cd $BUILD_DIR/rootfs/lib
sudo git clone --depth 1 https://github.com/rpi-distro/firmware-nonfree.git
sudo mv firmware-nonfree firmware
sudo rm -rf firmware/.git

cd $BUILD_DIR;

SuccessMessage "firmware install finished";
