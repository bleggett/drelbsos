ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-43}"
ARG SHA_HEAD_SHORT="${SHA_HEAD_SHORT}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"

ARG SOURCE_IMAGE="${SOURCE_IMAGE:-silverblue}"
ARG SOURCE_ORG="${SOURCE_ORG:-fedora-ostree-desktops}"
ARG BASE_IMAGE="quay.io/${SOURCE_ORG}/${SOURCE_IMAGE}"

FROM scratch AS ctx
COPY build_files /

FROM ghcr.io/bleggett/drelbsos-kernel:${FEDORA_MAJOR_VERSION} as drelbs-kernel
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS drelbsos

ARG IMAGE_NAME="${IMAGE_NAME:-drelbsos}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-43}"
ARG SHA_HEAD_SHORT="${SHA_HEAD_SHORT}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"

COPY system_files/ /

# Setup Copr repos (new)
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    export GPG_TTY=$(tty) && \
    /ctx/unwrap && \
    dnf5 -y install dnf5-plugins && \
    for copr in \
        # bazzite-org/bazzite \
        # bazzite-org/bazzite-multilib \
        ublue-os/staging \
        ublue-os/akmods \
        bazzite-org/LatencyFleX \
        bazzite-org/rom-properties \
        bazzite-org/webapp-manager \
        bazzite-org/vk_hdr_layer \
        hhd-dev/hhd \
        che/nerd-fonts \
        hikariknight/looking-glass-kvmfr \
        rok/cdemu \
        rodoma92/rmlint \
        barsnick/non-fed \
        erikreider/SwayNotificationCenter \
        ilyaz/LACT; \
    do \
        echo "Enabling copr: $copr"; \
        dnf5 -y copr enable $copr; \
        dnf5 -y config-manager setopt copr:copr.fedorainfracloud.org:${copr////:}.priority=98 ;\
    done && unset -v copr && \
    dnf5 config-manager addrepo --from-repofile="https://negativo17.org/repos/fedora-multimedia.repo" && \
    dnf5 config-manager setopt fedora-multimedia.priority=90 && \
    dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release{,-extras} && \
    dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/fedora-multimedia.repo && \
    dnf5 -y config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-rar.repo && \
    dnf5 -y config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-steam.repo && \
    dnf5 -y config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-nvidia.repo && \
    dnf5 config-manager addrepo --from-repofile=https://openrazer.github.io/hardware:razer.repo && \
    # dnf5 -y config-manager setopt "*bazzite*".priority=1 && \
    dnf5 -y config-manager setopt "*akmods*".priority=2 && \
    dnf5 -y config-manager setopt "*terra*".priority=3 "*terra*".exclude="nerd-fonts topgrade" && \
    dnf5 -y config-manager setopt "terra-mesa".enabled=true && \
    dnf5 -y config-manager setopt "terra-nvidia".enabled=false && \
    eval "$(/ctx/dnf5-setopt setopt '*fedora-multimedia*' priority=4 exclude='mesa-* *xone*')" && \
    dnf5 -y config-manager setopt "*rpmfusion*".priority=5 "*rpmfusion*".exclude="mesa-*" && \
    dnf5 -y config-manager setopt "*fedora*".exclude="mesa-* kernel-core-* kernel-modules-* kernel-uki-virt-*" && \
    dnf5 -y config-manager setopt "*staging*".exclude="scx-scheds kf6-* mesa* mutter* rpm-ostree* systemd* gnome-shell gnome-settings-daemon gnome-control-center gnome-software libadwaita tuned*" && \
    /ctx/cleanup

# Install kernel
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=drelbs-kernel,src=/kernel-rpms,dst=/var/kernel-rpms \
    --mount=type=bind,from=drelbs-kernel,src=/kmod-rpms,dst=/var/akmods-rpms \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/install-kernel-akmods && \
    dnf5 -y config-manager setopt "*rpmfusion*".enabled=0 && \
    dnf5 -y copr enable bieszczaders/kernel-cachyos-addons && \
    dnf5 -y install \
        scx-scheds && \
    dnf5 -y copr disable bieszczaders/kernel-cachyos-addons && \
    # dnf5 -y swap --repo copr:copr.fedorainfracloud.org:bazzite-org:bazzite bootc bootc && \
    /ctx/cleanup

# Install codec stuff
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 -y install --enable-repo="*rpmfusion*" --disable-repo="*fedora-multimedia*" \
        libaacs \
        libbdplus \
        libbluray \
        libbluray-utils && \
    /ctx/cleanup

# Remove unneeded packages
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 -y remove \
        ublue-os-update-services \
        opensc \
        # ffmpeg-free \
        # fdk-aac-free \
        # totem-video-thumbnailer \
        firefox \
        firefox-langpacks && \
    /ctx/cleanup

# Install new packages
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
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
        fdk-aac \
        ffmpeg \
        ffmpeg-libs \
        ffmpegthumbnailer \
        flatpak-spawn \
        fuse \
        fzf \
        grub2-tools-extra \
        heif-pixbuf-loader \
        htop \
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
        cyanrip \
        sway \
        swayidle \
        waybar \
        fuzzel \
        alacritty \
        pavucontrol \
        wev \
        SwayNotificationCenter \
        wlr-randr && \
    mkdir -p /etc/xdg/autostart && \
    sed -i 's/ --xdg-runtime=\\"${XDG_RUNTIME_DIR}\\"//g' /usr/bin/btrfs-assistant-launcher && \
    curl -Lo /usr/bin/installcab https://raw.githubusercontent.com/bazzite-org/steam-proton-mf-wmv/master/installcab.py && \
    chmod +x /usr/bin/installcab && \
    curl -Lo /usr/bin/install-mf-wmv https://github.com/bazzite-org/steam-proton-mf-wmv/blob/master/install-mf-wmv.sh && \
    chmod +x /usr/bin/install-mf-wmv && \
    curl -Lo /tmp/ls-iommu.tar.gz $(curl https://api.github.com/repos/HikariKnight/ls-iommu/releases/latest | jq -r '.assets[] | select(.name| test(".*x86_64.tar.gz$")).browser_download_url') && \
    mkdir -p /tmp/ls-iommu && \
    tar --no-same-owner --no-same-permissions --no-overwrite-dir -xvzf /tmp/ls-iommu.tar.gz -C /tmp/ls-iommu && \
    rm -f /tmp/ls-iommu.tar.gz && \
    cp -r /tmp/ls-iommu/ls-iommu /usr/bin/ && \
    /ctx/cleanup

# Configure GNOME overrides
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 -y install \
        # nautilus-gsconnect \
        # gnome-randr-rust \
        # gnome-shell-extension-appindicator \
        # gnome-shell-extension-gsconnect \
        firewall-config \
        rom-properties-gtk3 && \
    /ctx/cleanup

# Cleanup & Finalize
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    rm -f /etc/profile.d/toolbox.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    sed -i 's/#UserspaceHID.*/UserspaceHID=true/' /etc/bluetooth/input.conf && \
    # sed -i "s/^SCX_SCHEDULER=.*/SCX_SCHEDULER=scx_bpfland/" /etc/default/scx && \
    rm -f /usr/lib/systemd/system/service.d/50-keep-warm.conf && \
    mkdir -p "/etc/profile.d/" && \
    ln -s "/usr/share/ublue-os/firstboot/launcher/login-profile.sh" \
    "/etc/profile.d/ublue-firstboot.sh" && \
    mkdir -p "/etc/xdg/autostart" && \
    sed -i 's/stage/check/g' /etc/rpm-ostreed.conf && \
    dnf5 -y config-manager setopt "*ublue-os:akmods*".enabled=false && \
    for copr in \
        # bazzite-org/bazzite \
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
    eval "$(/ctx/dnf5-setopt setopt '*negativo17*' enabled=0)" && \
    mkdir -p /etc/flatpak/remotes.d && \
    curl -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo && \
    systemctl enable input-remapper.service && \
    systemctl enable dev-hugepages1G.mount && \
    systemctl --global enable podman.socket && \
    systemctl --global enable systemd-tmpfiles-setup.service && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/yad-icon-browser.desktop && \
    sed -i '/^PRETTY_NAME/s/Bazzite/DrelbsOS/' /usr/lib/os-release && \
    curl -Lo /etc/dxvk-example.conf https://raw.githubusercontent.com/doitsujin/dxvk/master/dxvk.conf && \
    curl -Lo /usr/lib/sysctl.d/99-bore-scheduler.conf https://github.com/CachyOS/CachyOS-Settings/raw/master/usr/lib/sysctl.d/99-bore-scheduler.conf && \
    curl -Lo /etc/distrobox/docker.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/docker/distrobox.ini && \
    curl -Lo /etc/distrobox/incus.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/incus/distrobox.ini && \
    /ctx/image-info && \
    /ctx/build-initramfs && \
    /ctx/finalize

RUN bootc container lint

FROM drelbsos AS drelbsos-nvidia

ARG IMAGE_NAME="${IMAGE_NAME:-drelbsos-nvidia}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-nvidia}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-43}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"

# Install NVIDIA driver
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=drelbs-kernel,src=/kmod-rpms,dst=/tmp/akmods-rpms \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 -y copr enable ublue-os/staging && \
    dnf5 -y install \
        mesa-vdpau-drivers.x86_64 \
        mesa-vdpau-drivers.i686 && \
    /ctx/nvidia-install && \
    rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json && \
    rm -f /usr/share/vulkan/icd.d/lvp_icd.*.json && \
    ln -s libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so && \
    dnf5 -y copr disable ublue-os/staging && \
    /ctx/cleanup

# Cleanup & Finalize
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/image-info && \
    /ctx/build-initramfs && \
    /ctx/finalize

RUN bootc container lint
