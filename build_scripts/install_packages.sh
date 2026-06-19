#!/bin/bash

set -ouex pipefail

echo "::group::Executing install_packages"
trap 'echo "::endgroup::"' EXIT

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROFILE="${PROFILE:-nvidia}"
PKG_FILE="${SCRIPT_DIR}/../profiles/${PROFILE}/packages"

mapfile -t PACKAGES < <(grep -vE '^\s*(#|$)' "${PKG_FILE}")

dnf5 -y install "${PACKAGES[@]}"
