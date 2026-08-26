#!/bin/bash

set -ouex pipefail

echo "::group::Executing final_clean"
trap 'echo "::endgroup::"' EXIT

# Clean up /boot
rm -rf /boot/*

# Rebuild and verify rpm's sqlite indexes and refuse to ship a database
# that still fails verification. rebuilddb finishes by renaming its scratch
# directory over the database directory, which is EXDEV when that directory
# still lives in a lower layer, so pull it into this one first. Runs before /var
# is cleared because rebuilddb wants /var/tmp.
DBPATH="$(rpm -E '%{_dbpath}')"
cp -a "${DBPATH}" "${DBPATH}.rebuild"
rm -rf "${DBPATH}"
mv "${DBPATH}.rebuild" "${DBPATH}"
rpmdb --rebuilddb
rpmdb --verifydb

# Clean up /var state that shouldn't be in the image
rm -rf /var/*
