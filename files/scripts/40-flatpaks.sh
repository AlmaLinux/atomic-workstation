#!/usr/bin/env bash

set -xeuo pipefail

# Install system Flatpaks
cat << 'EOF' >> /etc/flatpak/default-flatpaks/system/install
com.mattjakeman.ExtensionManager
com.github.tchx84.Flatseal
io.github.flattool.Warehouse
com.google.Chrome
org.mozilla.Thunderbird
io.github.dvlv.boxbuddyrs
org.libreoffice.LibreOffice
org.videolan.VLC
EOF

# Remove system Flatpaks
cat << 'EOF' >> /etc/flatpak/default-flatpaks/system/remove
org.gnome.Extensions
EOF
