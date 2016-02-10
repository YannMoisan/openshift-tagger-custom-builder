#!/bin/bash

# This script :
# - retrieves the commit id from the last image built
# - tag this image with the commit id

set -x # debug
set -e # fail fast
set -o pipefail
IFS=$'\n\t'

env | sort

echo $TOKEN
echo $BUILD_NAMESPACE
echo $BUILD_IMAGE
echo $OPENSHIFT_INSTANCE

if [ -z "$TOKEN" ]; then
  TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
fi

oc login --token=$TOKEN --server=$OPENSHIFT_INSTANCE
COMMIT_ID=$(oc get istag $BUILD_IMAGE:latest -o json -n $BUILD_NAMESPACE | jq -r ".image.dockerImageMetadata.Config.Labels.\"io.openshift.build.commit.id\"")
oc tag $BUILD_IMAGE:latest $BUILD_IMAGE:$COMMIT_ID -n $BUILD_NAMESPACE
