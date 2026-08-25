#!/bin/bash

set -ouex pipefail

echo "::group::Executing install_packages"
trap 'echo "::endgroup::"' EXIT

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROFILE="${PROFILE:-nvidia}"
PKG_FILE="${SCRIPT_DIR}/../profiles/${PROFILE}/packages"

EXCLUDE_FILE="${SCRIPT_DIR}/../profiles/${PROFILE}/excludes"

mapfile -t PACKAGES < <(grep -vE '^\s*(#|$)' "${PKG_FILE}")

EXCLUDES=()
if [[ -f "${EXCLUDE_FILE}" ]]; then
    mapfile -t EXCLUDED < <(grep -vE '^\s*(#|$)' "${EXCLUDE_FILE}")
    if [[ ${#EXCLUDED[@]} -gt 0 ]]; then
        EXCLUDES=("--exclude=$(IFS=,; echo "${EXCLUDED[*]}")")
    fi
fi

dnf5 -y install "${EXCLUDES[@]}" "${PACKAGES[@]}"
