#!/bin/bash

set -e
set -o pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 manifest" >&2
  exit 1
fi

if ! [ -e "$1" ]; then
  echo "$1 not found" >&2
  exit 1
fi

APP_NAME=$(jq -r .app.name $MANIFEST_FILE)
APP_VERSION=$(jq -r .app.version $MANIFEST_FILE)
EOS_VERSION=$(jq -r .edgeos.version $MANIFEST_FILE)
