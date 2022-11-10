#!/bin/bash

set -e
set -o pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 dir" >&2
  exit 1
fi

if ! [ -e "$1" ]; then
  echo "$1 not found" >&2
  exit 1
fi

if ! [ -d "$1" ]; then
  echo "$1 is not a directory" >&2
  exit 1
fi

source current-boot > /dev/null

if [ "$TRYBOOT" == "1" ]; then
    echo "An upgrade is already in progress, exiting!" >&2
    exit 1
fi

source read-manifest $1/manifest.json

if ! [ "$EDGEOS_VERSION" == "$CURRENT_EDGEOS_VERSION" ]; then
    echo "Upgrading EdgeOS from version $CURRENT_EDGEOS_VERSION to $EDGEOS_VERSION"
    # TODO Download and write EdgeOS
else
    echo "EdgeOS version $CURRENT_EDGEOS_VERSION is up to date"
fi

# TODO Write manifest and compose to other partition?
# TODO Reboot with tryboot