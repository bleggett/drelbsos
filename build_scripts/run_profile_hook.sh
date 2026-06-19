#!/bin/bash

set -ouex pipefail

# Runs profiles/<profile>/<hook>.sh if it exists, otherwise no-ops.
# $1 is the hook name (preinstall|postinstall).
HOOK="$1"

echo "::group::Executing run_profile_hook ${HOOK}"
trap 'echo "::endgroup::"' EXIT

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROFILE="${PROFILE:-nvidia}"
HOOK_SCRIPT="${SCRIPT_DIR}/../profiles/${PROFILE}/${HOOK}.sh"

if [[ -f "${HOOK_SCRIPT}" ]]; then
    echo "Running ${HOOK} hook for profile ${PROFILE}"
    bash "${HOOK_SCRIPT}"
else
    echo "No ${HOOK} hook for profile ${PROFILE}, skipping"
fi
