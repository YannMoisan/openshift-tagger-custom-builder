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

SKIP_TLS_VERIFY=${SKIP_TLS_VERIFY:-n}
CREATE_SHORT_TAG=${CREATE_SHORT_TAG:-y}


if [ -z "$TOKEN" ]; then
  TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
fi

oc_insecure=''
if [ $SKIP_TLS_VERIFY = "y" ];then
    oc_insecure='--insecure-skip-tls-verify'
fi

oc login $oc_insecure --token=$TOKEN --server=$OPENSHIFT_INSTANCE
COMMIT_ID=$(oc get istag $BUILD_IMAGE:latest -o json -n $BUILD_NAMESPACE | jq -r ".image.dockerImageMetadata.Config.Labels.\"io.openshift.build.commit.id\"")
oc tag $BUILD_IMAGE:latest $BUILD_IMAGE:$COMMIT_ID -n $BUILD_NAMESPACE

if [ "$COMMIT_ID" = "null" ];then
    echo "ERROR: No commit id found in $BUILD_IMAGE:latest labels"
    exit 1
fi

oc tag $BUILD_IMAGE:latest $BUILD_IMAGE:$COMMIT_ID -n $BUILD_NAMESPACE
[ $CREATE_SHORT_TAG = "y" ] && oc tag $BUILD_IMAGE:latest $BUILD_IMAGE:${COMMIT_ID::8} -n $BUILD_NAMESPACE
