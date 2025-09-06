#!/usr/bin/env bash

set -xeuo pipefail

# Multimedia codecs
dnf -y install \
    @multimedia \
    libcamera{,-{v4l2,gstreamer,tools}} \
    gstreamer1-plugins-{base,bad-free-libs} \
    lame{,-libs} \
    libjxl
