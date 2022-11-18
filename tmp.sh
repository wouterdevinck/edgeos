#!/bin/bash

# TODO remove - replaced by "make bundler"

VERSION=$(git describe --tags --dirty)
TAG="wouterdevinck/edgeos-bundler:$VERSION"

docker buildx build --load -t $TAG -f docker/Dockerfile-bundler .

ARGS="-v $(pwd)/bundler/example:/workdir -u $(id -u ${USER}):$(id -g ${USER})"
BUNDLER="docker run --rm $ARGS $TAG"

$BUNDLER create-upgrade
$BUNDLER create-image