#!/bin/bash

set -ouex pipefail

echo "::group::Executing final_clean"
trap 'echo "::endgroup::"' EXIT

# Clean up /boot
rm -rf /boot/*

# Clean up /var state that shouldn't be in the image
rm -rf /var/*
