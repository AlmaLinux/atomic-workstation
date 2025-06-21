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

# Now let's go for the main packages
dnf -y install \
    distrobox \
    buildah

systemctl enable rpm-ostree-countme.service

# Enable polkit rules for fingerprint sensors via fprintd
authselect enable-feature with-fingerprint
