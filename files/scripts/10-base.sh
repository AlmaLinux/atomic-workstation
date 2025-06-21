#!/usr/bin/env bash

set -xeuo pipefail

# Get rid of some stuff we don't need
dnf autoremove -y \
    PackageKit

# Start installing utilities and tools
dnf install -y \
    gnome-shell-extension-{appindicator,dash-to-dock,blur-my-shell} \
    ncdu \
    powertop \
    htop \
    fastfetch \
	systemd-{resolved,container,oomd} \
	libcamera{,-{v4l2,gstreamer,tools}} \
    jetbrains-mono-fonts-all

# Set up repo for Visual Studio Code
rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat << 'EOF' >> /etc/yum.repos.d/vscode.repo
# Visual Studio Code repository
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

# Now let's go for the main packages
dnf -y install \
    distrobox \
    buildah \
    code

systemctl enable rpm-ostree-countme.service

# Enable polkit rules for fingerprint sensors via fprintd
authselect enable-feature with-fingerprint
