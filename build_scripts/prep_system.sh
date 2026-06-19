#!/bin/bash

set -ouex pipefail

echo "::group::Executing prep_system"
trap 'echo "::endgroup::"' EXIT

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROFILE="${PROFILE:-nvidia}"
REPOS_FILE="${SCRIPT_DIR}/../profiles/${PROFILE}/repos"

rm -f /etc/profile.d/toolbox.sh && \
mkdir -p /var/tmp && chmod 1777 /var/tmp && \
sed -i 's/#UserspaceHID.*/UserspaceHID=true/' /etc/bluetooth/input.conf && \
rm -f /usr/lib/systemd/system/service.d/50-keep-warm.conf && \
mkdir -p "/etc/profile.d/" && \
mkdir -p "/etc/xdg/autostart" && \
sed -i 's/stage/check/g' /etc/rpm-ostreed.conf && \
mkdir -p /etc/flatpak/remotes.d && \
curl -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo && \
systemctl enable input-remapper.service && \
systemctl enable cups.service && \
systemctl enable dev-hugepages1G.mount && \
systemctl --global enable podman.socket && \
systemctl --global enable systemd-tmpfiles-setup.service && \
rm /usr/lib/systemd/system/default.target.wants/bootc-fetch-apply-updates.timer && \

# Disable the coprs this profile enabled in setup_repos.sh so the final image
# does not ship them enabled.
if [[ -f "${REPOS_FILE}" ]]; then
    while read -r copr; do
        dnf5 -y copr disable "${copr}"
    done < <(grep -vE '^\s*(#|$)' "${REPOS_FILE}")
fi
