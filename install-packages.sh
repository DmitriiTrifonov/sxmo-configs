#!/bin/sh
# Install user packages (packages.txt). Base/device-specific ones (packages-base.txt)
# come with the postmarketOS install for the device and are NOT installed here.
set -e
cd "$(dirname "$0")"
SU=$(command -v doas || command -v sudo)
$SU apk add $(grep -v '^#' packages.txt)
