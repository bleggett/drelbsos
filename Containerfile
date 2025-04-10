ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG BASE_IMAGE_FLAVOR="${BASE_IMAGE_FLAVOR:-main}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG NVIDIA_FLAVOR=${NVIDIA_FLAVOR:-nvidia}""
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR:-bazzite}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME-$BASE_IMAGE_FLAVOR}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-41}"
ARG SHA_HEAD_SHORT="${SHA_HEAD_SHORT}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"

FROM ghcr.io/ublue-os/akmods:${KERNEL_FLAVOR}-${FEDORA_MAJOR_VERSION} AS akmods
FROM ghcr.io/ublue-os/akmods-extra:${KERNEL_FLAVOR}-${FEDORA_MAJOR_VERSION} AS akmods-extra

FROM scratch AS ctx
COPY build_files /

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS drelbsos

ARG IMAGE_NAME="${IMAGE_NAME:-drelbsos}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG NVIDIA_FLAVOR="${NVIDIA_FLAVOR:-nvidia}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR:-bazzite}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-41}"
ARG SHA_HEAD_SHORT="${SHA_HEAD_SHORT}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"

COPY system_files/desktop/shared /

# Setup Copr repos (new)
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/unwrap && \
    dnf5 -y install dnf5-plugins && \
    for copr in \
        bazzite-org/bazzite \
        ublue-os/staging \
        bazzite-org/LatencyFleX \
        bazzite-org/rom-properties \
        bazzite-org/webapp-manager \
        bazzite-org/vk_hdr_layer \
        hhd-dev/hhd \
        che/nerd-fonts \
        hikariknight/looking-glass-kvmfr \
        rok/cdemu \
        rodoma92/rmlint \
        ilyaz/LACT; \
    do \
        dnf5 -y copr enable $copr; \
        dnf5 -y config-manager setopt copr:copr.fedorainfracloud.org:${copr////:}.priority=98 ;\
    done && unset -v copr && \
    dnf5 -y config-manager addrepo --overwrite --from-repofile=https://download.opensuse.org/repositories/hardware:/razer/Fedora_$(rpm -E %fedora)/hardware:razer.repo && \
    dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
    dnf5 -y config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-rar.repo && \
    dnf5 -y config-manager setopt "*bazzite*".priority=1 && \
    dnf5 -y config-manager setopt "*akmods*".priority=2 && \
    eval "$(/ctx/dnf5-setopt setopt '*negativo17*' priority=4 exclude='mesa-* *xone*')" && \
    dnf5 -y config-manager setopt "*rpmfusion*".priority=5 "*rpmfusion*".exclude="mesa-*" && \
    dnf5 -y config-manager setopt "*fedora*".exclude="mesa-* kernel-core-* kernel-modules-* kernel-uki-virt-*" && \
    dnf5 -y config-manager setopt "*staging*".exclude="scx-scheds kf6-* mesa* mutter* rpm-ostree* systemd* gnome-shell gnome-settings-daemon gnome-control-center gnome-software libadwaita tuned*" && \
    /ctx/cleanup

# Install kernel
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=akmods,src=/kernel-rpms,dst=/tmp/kernel-rpms \
    --mount=type=bind,from=akmods,src=/rpms,dst=/tmp/akmods-rpms \
    --mount=type=bind,from=akmods-extra,src=/rpms,dst=/tmp/akmods-extra-rpms \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/install-kernel-akmods && \
    dnf5 -y config-manager setopt "*rpmfusion*".enabled=0 && \
    dnf5 -y copr enable bieszczaders/kernel-cachyos-addons && \
    dnf5 -y install \
        scx-scheds && \
    dnf5 -y copr disable bieszczaders/kernel-cachyos-addons && \
    for toswap in rpm-ostree bootc; do \
        dnf5 -y swap --repo copr:copr.fedorainfracloud.org:bazzite-org:bazzite $toswap $toswap; \
    done && unset -v toswap && \
    /ctx/cleanup

# Install codec stuff
# Install patched fwupd
# Install Valve's patched Mesa, Pipewire, Bluez, and Xwayland
# Install patched switcheroo control with proper discrete GPU support
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
        xwiimote-ng \
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
        lsb_release \
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
 	nautilus-gsconnect \
        gnome-randr-rust \
        gnome-shell-extension-appindicator \
        gnome-shell-extension-user-theme \
        gnome-shell-extension-gsconnect \
        gnome-shell-extension-bazzite-menu \
        firewall-config \
        rom-properties-gtk3 && \
    /ctx/cleanup

# Cleanup & Finalize
COPY system_files/overrides /
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    rm -f /etc/profile.d/toolbox.sh && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    sed -i 's/#UserspaceHID.*/UserspaceHID=true/' /etc/bluetooth/input.conf && \
    sed -i "s/^SCX_SCHEDULER=.*/SCX_SCHEDULER=scx_bpfland/" /etc/default/scx && \
    rm -f /usr/lib/systemd/system/service.d/50-keep-warm.conf && \
    mkdir -p "/etc/profile.d/" && \
    ln -s "/usr/share/ublue-os/firstboot/launcher/login-profile.sh" \
    "/etc/profile.d/ublue-firstboot.sh" && \
    mkdir -p "/etc/xdg/autostart" && \
    echo "import \"/usr/share/ublue-os/just/81-bazzite-fixes.just\"" >> /usr/share/ublue-os/justfile && \
    echo "import \"/usr/share/ublue-os/just/84-bazzite-virt.just\"" >> /usr/share/ublue-os/justfile && \
    sed -i 's/stage/check/g' /etc/rpm-ostreed.conf && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo && \
    for copr in \
        bazzite-org/bazzite \
        ublue-os/staging \
        bazzite-org/LatencyFleX \
        bazzite-org/rom-properties \
        bazzite-org/webapp-manager \
        hhd-dev/hhd \
        che/nerd-fonts \
        lizardbyte/beta \
        hikariknight/looking-glass-kvmfr; \
    do \
        dnf5 -y copr disable $copr; \
    done && unset -v copr && \
    sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
    eval "$(/ctx/dnf5-setopt setopt '*negativo17*' enabled=0)" && \
    mkdir -p /etc/flatpak/remotes.d && \
    curl -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo && \
    systemctl enable input-remapper.service && \
    systemctl enable bazzite-flatpak-manager.service && \
    systemctl enable incus-workaround.service && \
    systemctl enable bazzite-hardware-setup.service && \
    systemctl enable dev-hugepages1G.mount && \
    systemctl --global enable bazzite-user-setup.service && \
    systemctl --global enable podman.socket && \
    systemctl --global enable systemd-tmpfiles-setup.service && \
    sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nNoDisplay=true@g' /usr/share/applications/yad-icon-browser.desktop && \
    sed -i '/^PRETTY_NAME/s/Bazzite/DrelbsOS/' /usr/lib/os-release && \
    curl -Lo /etc/dxvk-example.conf https://raw.githubusercontent.com/doitsujin/dxvk/master/dxvk.conf && \
    curl -Lo /usr/lib/sysctl.d/99-bore-scheduler.conf https://github.com/CachyOS/CachyOS-Settings/raw/master/usr/lib/sysctl.d/99-bore-scheduler.conf && \
    curl -Lo /etc/distrobox/docker.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/docker/distrobox.ini && \
    curl -Lo /etc/distrobox/incus.ini https://github.com/ublue-os/toolboxes/raw/refs/heads/main/apps/incus/distrobox.ini && \
    /ctx/build-initramfs && \
    /ctx/finalize && \
    /ctx/image-info

RUN bootc container lint

FROM ghcr.io/ublue-os/akmods-${NVIDIA_FLAVOR}:${KERNEL_FLAVOR}-${FEDORA_MAJOR_VERSION} AS nvidia-akmods

FROM drelbsos AS drelbsos-nvidia

ARG IMAGE_NAME="${IMAGE_NAME:-drelbsos-nvidia}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-nvidia}"
ARG NVIDIA_FLAVOR="${NVIDIA_FLAVOR:-nvidia}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR:-bazzite}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-41}"
ARG VERSION_TAG="${VERSION_TAG}"
ARG VERSION_PRETTY="${VERSION_PRETTY}"

# Install NVIDIA driver
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=nvidia-akmods,src=/rpms,dst=/tmp/akmods-rpms \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 -y copr enable ublue-os/staging && \
    dnf5 -y install \
        mesa-vdpau-drivers.x86_64 \
        mesa-vdpau-drivers.i686 && \
    curl -Lo /tmp/nvidia-install.sh https://raw.githubusercontent.com/ublue-os/hwe/1ea2a91b839fc8d635fdf546a74e66bc4eb48c2a/nvidia-install.sh && \
    chmod +x /tmp/nvidia-install.sh && \
    IMAGE_NAME="${BASE_IMAGE_NAME}" /tmp/nvidia-install.sh && \
    rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json && \
    rm -f /usr/share/vulkan/icd.d/lvp_icd.*.json && \
    ln -s libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so && \
    dnf5 -y copr disable ublue-os/staging && \
    /ctx/cleanup

   #  sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \

   #  sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/rpmfusion*.repo && \
   #  sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-cisco-openh264.repo && \
   #  dnf5 install -y /tmp/akmods-rpms/ublue-os/ublue-os-nvidia-addons-*.rpm && \
   #  sed -i '0,/enabled=0/{s/enabled=0/enabled=1/}' /etc/yum.repos.d/negativo17-fedora-nvidia.repo && \
   #  sed -i '0,/enabled=0/{s/enabled=0/enabled=1/}' /etc/yum.repos.d/nvidia-container-toolkit.repo && \
   #  sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
   #  source /tmp/akmods-rpms/kmods/nvidia-vars && \

   #  dnf5 install -y \
   #      libnvidia-fbc \
   #      libnvidia-ml.i686 \
   #      libva-nvidia-driver \
   #      nvidia-driver \
   #      nvidia-driver-cuda \
   #      nvidia-driver-libs.i686 \
   #      # TODO needed for x86
   #      vulkan-loader.i686 \
   #      nvidia-settings \
   #      nvidia-container-toolkit ${VARIANT_PKGS} \
   #      /tmp/akmods-rpms/kmods/kmod-nvidia*.fc${RELEASE}.rpm && \

   # sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/negativo17-fedora-nvidia.repo && \
   # sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/nvidia-container-toolkit.repo && \

   # sed -i "s/^MODULE_VARIANT=.*/MODULE_VARIANT=$KERNEL_MODULE_TYPE/" /etc/nvidia/kernel.conf && \

   # systemctl enable ublue-nvctk-cdi.service && \
   # semodule --verbose --install /usr/share/selinux/packages/nvidia-container.pp && \

   # # Universal Blue specific Initramfs fixes
   # cp /etc/modprobe.d/nvidia-modeset.conf /usr/lib/modprobe.d/nvidia-modeset.conf && \
   # sed -i 's@omit_drivers@force_drivers@g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf && \
   # sed -i 's@ nvidia @ i915 amdgpu nvidia @g' /usr/lib/dracut/dracut.conf.d/99-nvidia.conf && \

   # rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json && \
   # rm -f /usr/share/vulkan/icd.d/lvp_icd.*.json && \
   # ln -s libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so && \
   # dnf5 -y copr disable ublue-os/staging && \
   # /ctx/cleanup

# Cleanup & Finalize
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build-initramfs && \
    /ctx/finalize && \
    /ctx/image-info

RUN bootc container lint
