#!/usr/bin/env bash

# DO NOT MODIFY THIS FILE UNLESS YOU KNOW WHAT YOU ARE DOING

set -xeuo pipefail

VERSION_ID="$(sh -c '. /usr/lib/os-release ; echo $VERSION_ID')"
IMAGE_PRETTY_NAME="AlmaLinux Atomic Workstation"

# Add our image name as VARIANT_ID.
# This may help us get some usage stats through countme data.
cat /usr/lib/os-release
sed -i -f - /usr/lib/os-release <<EOF
s/^NAME=.*/NAME=\"${IMAGE_PRETTY_NAME}\"/
s/^PRETTY_NAME=.*/PRETTY_NAME=\"${IMAGE_PRETTY_NAME} ${VERSION_ID}\"/

/^VARIANT_ID=/d
\$a\
VARIANT_ID=\"${IMAGE_NAME}\"
EOF
cat /usr/lib/os-release
