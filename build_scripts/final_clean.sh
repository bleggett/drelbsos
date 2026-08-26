#!/bin/bash

set -ouex pipefail

echo "::group::Executing final_clean"
trap 'echo "::endgroup::"' EXIT

# Clean up /boot
rm -rf /boot/*

# Refuse to ship an rpm database that fails verification. Verification only:
# corruption in the Packages table makes rebuilddb stop at the first bad page
# and emit a database that verifies clean while missing most of its headers.
rpmdb --verifydb

# Clean up /var state that shouldn't be in the image
rm -rf /var/*
