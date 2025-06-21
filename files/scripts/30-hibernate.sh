#!/usr/bin/env bash

set -xeuo pipefail

# Add resume module so that hibernation works
echo "add_dracutmodules+=\" resume \"" >/etc/dracut.conf.d/resume.conf
KERNEL_SUFFIX=""
QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-(|'"$KERNEL_SUFFIX"'-)(\d+\.\d+\.\d+)' | sed -E 's/kernel-(|'"$KERNEL_SUFFIX"'-)//' | tail -n 1)"
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
