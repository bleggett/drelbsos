#!/bin/bash

set -ouex pipefail

echo "::group::Executing prep_system"
trap 'echo "::endgroup::"' EXIT

rm -f /etc/profile.d/toolbox.sh && \
mkdir -p /var/tmp && chmod 1777 /var/tmp && \
sed -i 's/#UserspaceHID.*/UserspaceHID=true/' /etc/bluetooth/input.conf && \
rm -f /usr/lib/systemd/system/service.d/50-keep-warm.conf && \
mkdir -p "/etc/profile.d/" && \
ln -s "/usr/share/ublue-os/firstboot/launcher/login-profile.sh" \
"/etc/profile.d/ublue-firstboot.sh" && \
mkdir -p "/etc/xdg/autostart" && \
sed -i 's/stage/check/g' /etc/rpm-ostreed.conf && \
dnf5 -y config-manager setopt "*ublue-os:akmods*".enabled=false && \
for copr in \
    ublue-os/staging \
    bazzite-org/LatencyFleX \
    bazzite-org/rom-properties \
    bazzite-org/webapp-manager \
    hhd-dev/hhd \
    che/nerd-fonts \
    lizardbyte/beta \
    erikreider/SwayNotificationCenter \
    hikariknight/looking-glass-kvmfr; \
do \
    dnf5 -y copr disable $copr; \
done && unset -v copr && \
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-multimedia.repo && \
repos=$(dnf5 repo list --all | awk '/negativo17/ {print $1".enabled=0"}')
[[ -n "$repos" ]] && dnf5 -y config-manager setopt $repos && \
mkdir -p /etc/flatpak/remotes.d && \
curl -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo && \
systemctl enable input-remapper.service && \
systemctl enable dev-hugepages1G.mount && \
systemctl --global enable podman.socket && \
systemctl --global enable systemd-tmpfiles-setup.service && \
sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/yad-icon-browser.desktop && \
sed -i '/^PRETTY_NAME/s/Bazzite/DrelbsOS/' /usr/lib/os-release && \
curl -Lo /etc/dxvk-example.conf https://raw.githubusercontent.com/doitsujin/dxvk/master/dxvk.conf && \
curl -Lo /etc/distrobox/docker.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/docker/distrobox.ini && \
curl -Lo /etc/distrobox/incus.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/incus/distrobox.ini
