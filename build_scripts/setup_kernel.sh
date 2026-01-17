#!/bin/bash

set -ouex pipefail

echo "::group::Executing setup_kernel"
trap 'echo "::endgroup::"' EXIT

dnf5 -y remove --no-autoremove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra

dnf5 -y install \
    /var/kernel-rpms/kernel-[0-9]*.rpm \
    /var/kernel-rpms/kernel-core-*.rpm \
    /var/kernel-rpms/kernel-modules-*.rpm \
    /var/kernel-rpms/kernel-devel-*.rpm

dnf5 versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-uki-virt

# Everything but the nvidia kmods
dnf5 -y install $(find /var/akmods-rpms/kmods/ -name "*.rpm" ! -name "*nvidia*.rpm")
