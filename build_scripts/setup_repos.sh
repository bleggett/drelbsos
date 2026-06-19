#!/bin/bash

set -ouex pipefail

echo "::group::Executing setup_repos"
trap 'echo "::endgroup::"' EXIT

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROFILE="${PROFILE:-nvidia}"
REPOS_FILE="${SCRIPT_DIR}/../profiles/${PROFILE}/repos"

dnf5 -y install dnf5-plugins

if [[ -f "${REPOS_FILE}" ]]; then
    while read -r copr; do
        echo "Enabling copr: ${copr}"
        dnf5 -y copr enable "${copr}"
        dnf5 -y config-manager setopt "copr:copr.fedorainfracloud.org:${copr////:}.priority=98"
    done < <(grep -vE '^\s*(#|$)' "${REPOS_FILE}")
else
    echo "No repos file at ${REPOS_FILE}, skipping copr enables"
fi
