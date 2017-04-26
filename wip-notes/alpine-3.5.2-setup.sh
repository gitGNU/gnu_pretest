#!/bin/sh

# Setup script for AlpineLinux
# for https://www.nongnu.org/pretest

# Upgrade kernel to latest to avoid sshd stuckage
# see https://bugs.alpinelinux.org/issues/6635
#sed -i -e '/^#/!s/^/#/' -e '/edge\/main/s/^#//' /etc/apk/repositories
#apk upgrade --update-cache --available
wget http://mirror.leaseweb.com/alpine/edge/main/x86_64/linux-virtgrsec-4.9.24-r0.apk


# Enable root to login with SSH with a passsowrd
sed -i -e '/PermitRootLogin/s/.*/PermitRootLogin yes/' /etc/ssh/sshd_config
rc-service sshd restart


# Enable Serial console on boot
sed -i -e '/^default_kernel_opts=/s/=.*/="console=ttyS0,9600 console=tty0"/' \
    -e '/^verbose=/s/=.*/=1/' \
    -e '/^hidden=/s/=.*/=/' \
    -e '/^timeout=/s/=.*/=1/' \
    -e '/^serial_port=/s/=.*/=0/' \
    -e '/^serial_baud=/s/=.*/=9600/' \
    /etc/update-extlinux.conf

update-extlinux

# Enable Serial-console login
## no need: alpine-3.5.2 already has one enabled by default.
## sed -i -e '/ttyS0/s/^#//' -e '/ttyS0/s/115200/9600/' /etc/inittab

# install sudo
apk add sudo

# 'Wheel' group can sudo without a password
sed -i -e '/%wheel.*NOPASSWD/s/^# *//' /etc/sudoers

# Add user
adduser -D -g "" miles
echo "miles:12345" | chpasswd
adduser miles wheel
