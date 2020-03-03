#! /usr/bin/env bash

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

#echo "Prepare to build UbuntuKylin rootfs"
SuccessMessage "Prepare to build UbuntuKylin rootfs...";

StdMessage "Install necessary dependencies";

sudo apt install -y install debootstrap binfmt-support qemu-user-static;

if [ $1 == "debian" ]; then
  sudo apt install -y ubuntu-archive-keyring;
fi

SuccessMessage "Dependencies installed success";

sudo update-binfmts --enable qemu-aarch64;

StdMessage "Start install ubuntu base system to rootfs";

sudo mkdir -p rootfs
sudo mkdir -p rootfs/usr/share/keyrings

sudo qemu-debootstrap --arch arm64 focal rootfs http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/

SuccessMessage "Ubuntu base system installed success".

sudo mount -t sysfs sysfs rootfs/sys/
sudo mount -t proc proc rootfs/proc/
sudo mount -o bind /dev rootfs/dev/
sudo mount -o bind /dev/pts rootfs/dev/pts

StdMessage "Start system configuration"

echo "ubuntukylin" | sudo tee rootfs/etc/hostname
cat <<"EOM" > /dev/stdout | sudo tee rootfs/etc/hosts
127.0.0.1 localhost
::1       localhost ip6-localhost ip6loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters
127.0.0.1 localhost.localdomain
EOM

HOST_HOSTNAME='hostname'
sudo chroot rootfs env -i bin/hostname -F /etc/hostname

sudo chroot rootfs apt update

sudo chroot rootfs env -i HOME="/root" PATH="/bin:/usr/bin:/sbin:/usr/sbin" TERM="$TERM" DEBIAN_FRONTEND="noninteractive" \
    apt --yes -o DPkg::Options::=--force-confdef install  --no-install-recommends whiptail

sudo chroot rootfs env -i HOME="/root" PATH="/bin:/usr/bin:/sbin:/usr/sbin" TERM="$TERM" \
    apt --yes -o DPkg::Options::=--force-confdef install  --no-install-recommends locales
sudo chroot rootfs env -i HOME="/root" PATH="/bin:/usr/bin:/sbin:/usr/sbin" TERM="$TERM" SHELL="/bin/bash" \
    dpkg-reconfigure locales

sudo chroot rootfs env -i HOME="/root" PATH="/bin:/usr/bin:/sbin:/usr/sbin" TERM="$TERM" \
	  apt --yes -o DPkg::Options::=--force-confdef install  --no-install-recommends sudo ssh net-tools ethtool wireless-tools init iputils-ping rsyslog bash-completion ifupdown 

sudo chroot rootfs env -i HOME="/root" PATH="/bin:/usr/bin:/sbin:/usr/sbin" TERM="$TERM" \
    apt --yes -o DPkg::Options::=--force-confdef upgrade

sudo chroot rootfs useradd -G sudo,adm -m -s /bin/bash kylin
sudo chroot rootfs sh -c "echo 'kylin:kylin' | chpasswd"

sudo chroot rootfs apt --yes clean
sudo chroot rootfs apt --yes autoclean
sudo chroot rootfs apt --yes autoremove

sudo chroot rootfs env -i /bin/hostname $HOST_HOSTNAME

sudo umount ./rootfs/dev/pts
sudo umount ./rootfs/dev
sudo umount ./rootfs/proc
sudo umount ./rootfs/sys


cat <<"EOM" > /dev/stdout | sudo tee rootfs/etc/fstab
proc            /proc           proc    defaults                  0       0
/dev/mmcblk0p1  /boot           vfat    defaults                  0       2
/dev/mmcblk0p2  /               ext4    defaults,noatime          0       1
EOM

cd $BUILD_DIR;

echo "RASPKYLIN_VER=" > .kylinrpi
echo "ROOTFS=arm64" >> .kylinrpi

SuccessMessage "System configruation finished"

exit 1;
