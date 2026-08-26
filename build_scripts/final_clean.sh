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

# Fingerprint the database as the build sees it, to compare against the same
# file read back out of the committed image. The O_DIRECT read bypasses the page
# cache: if it disagrees with the cached read, the correct bytes are only in
# memory and have not reached disk, which would explain a clean read here and a
# corrupt one after the layer commit.
DBFILE="$(rpm -E '%{_dbpath}')/rpmdb.sqlite"
stat -c '::notice::RPMDB-SRC apparent=%s allocated=%b*%B' "${DBFILE}"
CACHED=$(sha256sum "${DBFILE}" | cut -d' ' -f1)
DIRECT=$(dd if="${DBFILE}" bs=1M iflag=direct status=none | sha256sum | cut -d' ' -f1) \
    || DIRECT="O_DIRECT-unsupported"
sync
POSTSYNC=$(dd if="${DBFILE}" bs=1M iflag=direct status=none | sha256sum | cut -d' ' -f1) \
    || POSTSYNC="O_DIRECT-unsupported"
# Emitted as workflow notices so they surface outside the collapsed log group.
echo "::notice::RPMDB-SRC cached=${CACHED}"
echo "::notice::RPMDB-SRC ondisk=${DIRECT}"
echo "::notice::RPMDB-SRC post-sync=${POSTSYNC}"

# Clean up /var state that shouldn't be in the image
rm -rf /var/*
