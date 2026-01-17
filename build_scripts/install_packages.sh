#!/bin/bash

set -ouex pipefail

echo "::group::Executing install_packages"
trap 'echo "::endgroup::"' EXIT

dnf5 -y remove \
    ublue-os-update-services \
    firefox \
    firefox-langpacks

# dnf5 -y install --enable-repo="*rpmfusion*" --disable-repo="*fedora-multimedia*" \
#     libaacs \
#     libbdplus \
#     libbluray \
#     libbluray-utils \
#     fdk-aac \
#     ffmpeg-libs \
#     ffmpegthumbnailer \
#     ffmpeg

dnf5 -y install \
    twitter-twemoji-fonts \
    lato-fonts \
    fira-code-fonts \
    nerd-fonts \
    google-droid-sans-mono-fonts \
    python3-pip \
    duperemove \
    sqlite \
    xwininfo \
    xrandr \
    ddcutil \
    input-remapper \
    i2c-tools \
    lm_sensors \
    udica \
    python3-icoextract \
    webapp-manager \
    zsh \
    btop \
    libaacs \
    libbdplus \
    libbluray \
    libbluray-utils \
    fdk-aac \
    ffmpeg-libs \
    ffmpegthumbnailer \
    ffmpeg
    xdotool \
    wmctrl \
    libcec \
    yad \
    f3 \
    lzip \
    p7zip \
    rar \
    libxcrypt-compat \
    vulkan-tools \
    fastfetch \
    topgrade \
    ydotool \
    cdemu-daemon \
    cdemu-client \
    gcdemu \
    openrazer-daemon \
    egl-utils \
    ncdu \
    btrfs-assistant \
    podman-compose \
    edk2-ovmf \
    qemu \
    unetbootin \
    libvirt \
    antimicrox \
    lsb_release \
    alsa-firmware \
    android-udev-rules \
    distrobox \
    flatpak-spawn \
    fuse \
    fzf \
    grub2-tools-extra \
    heif-pixbuf-loader \
    htop \
    iperf3 \
    libavcodec \
    libcamera \
    libcamera-tools \
    libcamera-gstreamer \
    libcamera-ipa \
    libheif \
    libratbag-ratbagd \
    libva-utils \
    lshw \
    net-tools \
    nvme-cli \
    nvtop \
    openrgb-udev-rules \
    openssl \
    pam-u2f \
    pam_yubico \
    pamu2fcfg \
    pipewire-libs-extra \
    pipewire-plugin-libcamera \
    powerstat \
    lxpolkit \
    smartmontools \
    squashfs-tools \
    symlinks \
    tcpdump \
    screen \
    traceroute \
    vim \
    wireguard-tools \
    wl-clipboard \
    xhost \
    xorg-x11-xauth \
    yubikey-manager \
    zstd \
    adw-gtk3-theme \
    gvfs-nfs \
    gstreamer1-plugin-libav \
    gstreamer1-plugins-ugly \
    gstreamer1-plugins-bad \
    gstreamer1-plugins-good-extras \
    openssh-askpass \
    cyanrip \
    sway \
    swayidle \
    waybar \
    fuzzel \
    alacritty \
    pcsc-lite-devel \
    mediawriter \
    pavucontrol \
    wev \
    SwayNotificationCenter \
    firewall-config \
    rom-properties-gtk3
    wlr-randr && \

# Random binaries
curl -Lo /tmp/ls-iommu.tar.gz $(curl https://api.github.com/repos/HikariKnight/ls-iommu/releases/latest | jq -r '.assets[] | select(.name| test(".*x86_64.tar.gz$")).browser_download_url') && \
mkdir -p /tmp/ls-iommu && \
tar --no-same-owner --no-same-permissions --no-overwrite-dir -xvzf /tmp/ls-iommu.tar.gz -C /tmp/ls-iommu && \
rm -f /tmp/ls-iommu.tar.gz && \
cp -r /tmp/ls-iommu/ls-iommu /usr/bin/
