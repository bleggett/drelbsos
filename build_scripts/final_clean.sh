#!/bin/bash

set -ouex pipefail

echo "::group::Executing final_clean"
trap 'echo "::endgroup::"' EXIT

# Clean up /boot
RUN rm -rf /boot/*

# Clean up /var state that shouldn't be in the image
RUN rm -rf /var/lib/dnf/repos/* \
    && rm -f /var/lib/freeipmi/ipckey \
    && find /var -type f -name 'countme' -delete
