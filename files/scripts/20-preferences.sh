#!/usr/bin/env bash

set -xeuo pipefail

# Set some bash aliases
cat << 'EOF' > /etc/profile.d/bash_aliases.sh
alias ls='ls --color=auto'
alias ll='ls -la'
EOF
