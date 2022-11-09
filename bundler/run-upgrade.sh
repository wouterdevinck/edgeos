#!/bin/bash

set -e
set -o pipefail

TMPDIR=tmp
MANIFEST_FILE="$TMPDIR/manifest.json"
INSTALL_SCRIPT_FILE="$TMPDIR/install.sh"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 *.upg" >&2
  exit 1
fi

if ! [ -e "$1" ]; then
  echo "$1 not found" >&2
  exit 1
fi

mkdir -p $TMPDIR

tar -xf $1 -C $TMPDIR

if ! [ -e "$MANIFEST_FILE" ]; then
  echo "$MANIFEST_FILE not found" >&2
  exit 1
fi

if ! [ -e "$INSTALL_SCRIPT_FILE" ]; then
  echo "$INSTALL_SCRIPT_FILE not found" >&2
  exit 1
fi

source read-manifest.sh $MANIFEST_FILE

echo "Running install script from package $APP_NAME version $APP_VERSION"

$INSTALL_SCRIPT_FILE

rm -rf $TMPDIR