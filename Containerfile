ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-44}"

ARG BASE_IMAGE="quay.io/fedora/fedora-bootc"

FROM scratch AS ctx
COPY build_scripts /scripts
COPY profiles /profiles

FROM ghcr.io/bleggett/drelbsos-kernel:${FEDORA_MAJOR_VERSION} as drelbs-kernel
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS drelbsos

ARG IMAGE_NAME="${IMAGE_NAME:-drelbsos}"
ARG IMAGE_BRANCH="${IMAGE_BRANCH:-main}"
ARG IMAGE_BUILDID="${IMAGE_BUILDID}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-44}"
ARG PROFILE="${PROFILE:-nvidia}"

# Setup Copr repos
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/scripts/setup_repos.sh

# Install kernel
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp:exec \
    --mount=type=bind,from=drelbs-kernel,src=/kernel-rpms,dst=/var/kernel-rpms \
    --mount=type=bind,from=drelbs-kernel,src=/kmod-rpms,dst=/var/akmods-rpms \
    /ctx/scripts/setup_kernel.sh

# Profile preinstall hook (optional, skipped if absent)
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/scripts/run_profile_hook.sh preinstall

# Install stuff
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/scripts/install_packages.sh

# Some of these overlay package files, so need to do them post-package-install.
COPY overlay_files /

# Profile postinstall hook (optional, skipped if absent; e.g. nvidia drivers).
# The drelbs-kernel kmod mount is provided for hooks that build kmods.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=drelbs-kernel,src=/kmod-rpms,dst=/tmp/akmods-rpms \
    /ctx/scripts/run_profile_hook.sh postinstall

# Cleanup & Finalize
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/scripts/prep_system.sh && \
    /ctx/scripts/setup_image_info.sh && \
    /ctx/scripts/build_initramfs.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/scripts/final_clean.sh && \
    bootc container lint
