#!/usr/bin/bash

set -eoux pipefail

echo "::group::Executing setup_image_info"
trap 'echo "::endgroup::"' EXIT

IMAGE_PRETTY_NAME="DrelbsOS"
IMAGE_LIKE="fedora"
HOME_URL="https://github.com/bleggett/drelbsos"
DOCUMENTATION_URL="https://github.com/bleggett/drelbsos"
SUPPORT_URL="https://github.com/bleggett/drelbsos"
BUG_SUPPORT_URL="https://github.com/bleggett/drelbsos"
CODE_NAME="Trollaboar"
BASE_IMAGE_NAME="bootc"
IMAGE_VENDOR="drelbszoomer"

# OS Release File
sed -i "s/^VARIANT_ID=.*/VARIANT_ID=$IMAGE_NAME/" /usr/lib/os-release
sed -i "s/^PRETTY_NAME=.*/PRETTY_NAME=\"DrelbsOS $FEDORA_MAJOR_VERSION (FROM Fedora ${BASE_IMAGE_NAME^})\"/" /usr/lib/os-release
sed -i "s/^NAME=.*/NAME=\"$IMAGE_PRETTY_NAME\"/" /usr/lib/os-release
sed -i "s|^HOME_URL=.*|HOME_URL=\"$HOME_URL\"|" /usr/lib/os-release
sed -i "s|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL=\"$DOCUMENTATION_URL\"|" /usr/lib/os-release
sed -i "s|^SUPPORT_URL=.*|SUPPORT_URL=\"$SUPPORT_URL\"|" /usr/lib/os-release
sed -i "s|^BUG_REPORT_URL=.*|BUG_REPORT_URL=\"$BUG_SUPPORT_URL\"|" /usr/lib/os-release
sed -i "s|^CPE_NAME=\"cpe:/o:fedoraproject:fedora|CPE_NAME=\"cpe:/o:${IMAGE_VENDOR}:${IMAGE_PRETTY_NAME,,}|" /usr/lib/os-release
sed -i "s/^DEFAULT_HOSTNAME=.*/DEFAULT_HOSTNAME=\"${IMAGE_PRETTY_NAME,,}\"/" /usr/lib/os-release
sed -i "s/^ID=fedora/ID=${IMAGE_PRETTY_NAME,,}\nID_LIKE=\"${IMAGE_LIKE}\"/" /usr/lib/os-release
sed -i "/^REDHAT_BUGZILLA_PRODUCT=/d; /^REDHAT_BUGZILLA_PRODUCT_VERSION=/d; /^REDHAT_SUPPORT_PRODUCT=/d; /^REDHAT_SUPPORT_PRODUCT_VERSION=/d" /usr/lib/os-release
sed -i "s|^VERSION_CODENAME=.*|VERSION_CODENAME=\"$CODE_NAME\"|" /usr/lib/os-release

echo "BUILD_ID=\"$IMAGE_BUILDID\"" >> /usr/lib/os-release

echo "BOOTLOADER_NAME=\"$IMAGE_PRETTY_NAME $IMAGE_BUILDID\"" >> /usr/lib/os-release

# Fix issues caused by ID no longer being fedora
sed -i "s/^EFIDIR=.*/EFIDIR=\"fedora\"/" /usr/sbin/grub2-switch-to-blscfg
