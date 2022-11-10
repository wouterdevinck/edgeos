#!/bin/bash

set -e
set -o pipefail

INSTALL_SCRIPT_FILE="install.sh"
MANIFEST_FILE="manifest.json"
DOCKER_COMPOSE_FILE="docker-compose.yml"

source read-manifest $MANIFEST_FILE

PACKAGENAME="$APP_NAME-$APP_VERSION.upg"

echo "Creating upgrade package $PACKAGENAME"

tar -czvf $PACKAGENAME $INSTALL_SCRIPT_FILE $MANIFEST_FILE $DOCKER_COMPOSE_FILE