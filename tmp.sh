#!/bin/bash

TAG="wouterdevinck/edgeos-bundler:0.0.0"

docker buildx build --load -t $TAG -f docker/Dockerfile-bundler .

ARGS="-v $(pwd)/bundler:/workdir -u $(id -u ${USER}):$(id -g ${USER})"
BUNDLER="docker run --rm $ARGS $TAG"

$BUNDLER create-upgrade
$BUNDLER create-image