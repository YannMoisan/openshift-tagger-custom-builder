#!/bin/bash

# This script :
# - retrieves the commit id from BUILD variable "triggeredBy" field
# - if not present then retrieves the commit id from the last image built
#   ("latest" tag) using its labels assigned by s2i process
# - tag this image with the full commit id and optionally truncated versions
#   (first 8 chars)
# - if requested it can also push tag to source docker registry
#   (requires exposed docker socket)

is_debug() { [ "${DEBUG:-n}" = "y" ] && return 0 || return 1; }
log_debug() { is_debug && echo "DEBUG: $@" >&2; }
log_info() { echo "INFO: $@"; }
log_error() { echo "ERROR: $@" >&2; }

is_debug && set -x
set -e
set -o pipefail
IFS=$'\n\t'

is_debug && env | sort
# log_debug "PWD=$PWD USER=$USER HOME=$HOME"

: ${SKIP_TLS_VERIFY:=n}
: ${CREATE_SHORT_TAG:=y}
: ${CREATE_LONG_TAG:=y}
: ${OPENSHIFT_INSTANCE:=kubernetes.default.svc}
: ${PUSH_TO_DOCKER:=n}

is_debug && echo $TOKEN
cat << EOP
CONFIG:

Namespace of the ImageStream: $BUILD_NAMESPACE
ImageStream: $BUILD_IMAGE
Kubernetes Endpoint: $OPENSHIFT_INSTANCE
Skip TLS verification: $SKIP_TLS_VERIFY
Create short tag (8 first chars of commit id): $CREATE_SHORT_TAG
Create long tag (full 40 chars commit id): $CREATE_LONG_TAG
Push tag to docker registry: $PUSH_TO_DOCKER

EOP



if [ -z "$TOKEN" ]; then
  log_info "Reading token from mounted secret"
  TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
fi

oc_insecure=''
if [ $SKIP_TLS_VERIFY = "y" ];then
    log_info "Setting 'insecure-skip-tls-verify' option for oc"
    oc_insecure='--insecure-skip-tls-verify'
fi

oc login $oc_insecure --token=$TOKEN --server=$OPENSHIFT_INSTANCE

is_debug && { log_debug "BUILD info:"; echo $BUILD|jq '.'; }

# get image which triggered this job
UPSTREAM_IMAGE=$(jq -nr '(env.BUILD|fromjson).spec.triggeredBy[0].imageChangeBuild.imageID')
UPSTREAM_IMAGESTREAM=$(jq -nr '(env.BUILD|fromjson).spec.triggeredBy[0].imageChangeBuild.fromRef.name'|cut -f1 -d:)
# try to read sha256 id of the image - it's more reliable than just latest tag
# which might lead to unexpected results when multiple jobs would be triggered
UPSTREAM_IMAGE_ID=$(echo $UPSTREAM_IMAGE|sed -e 's/.*@\(sha256:.*\)/\1/')
UPSTREAM_IMAGE_NAME=$(echo $UPSTREAM_IMAGE|sed -e 's/\(.*\)@sha256:.*/\1/')

if [ "$UPSTREAM_IMAGESTREAM" = "null" -a -z "$BUILD_IMAGE" ];then
  log_error "Could not find imagestream name in triggered build info and BUILD_IMAGE is not set (manually triggered?). Aborting."
  exit 1
elif [ -z "$BUILD_IMAGE" ];then
  log_info "Setting discovered imagestream from triggered build info"
  BUILD_IMAGE="$UPSTREAM_IMAGESTREAM"
fi


if [ "$UPSTREAM_IMAGE_ID" = "null" ];then
  log_info "No image id found in triggered build info - using 'latest' tag (manually triggered?)"
  COMMIT_ID=$(oc get istag $BUILD_IMAGE:latest -o json -n $BUILD_NAMESPACE | jq -r ".image.dockerImageMetadata.Config.Labels.\"io.openshift.build.commit.id\"")
  SRC_IMAGE="$BUILD_IMAGE:latest"
else
  log_info "Found id of upstream build which triggered this job: $UPSTREAM_IMAGE_ID"
  COMMIT_ID=$(oc get isimage $BUILD_IMAGE@${UPSTREAM_IMAGE_ID} -o json -n $BUILD_NAMESPACE | jq -r ".image.dockerImageMetadata.Config.Labels.\"io.openshift.build.commit.id\"")
  SRC_IMAGE="$BUILD_IMAGE@${UPSTREAM_IMAGE_ID}"
fi

if [ "$COMMIT_ID" = "null" ];then
    log_error "No commit id found in $SRC_IMAGE labels"
    exit 1
fi

NEW_TAGS=()

[ $CREATE_SHORT_TAG = "y" ] && NEW_TAGS=(${NEW_TAGS[@]} ${COMMIT_ID::8})
[ $CREATE_LONG_TAG = "y" ] && NEW_TAGS=(${NEW_TAGS[@]} $COMMIT_ID)

if [[ -d /var/run/secrets/openshift.io/push ]] && [[ ! -e /root/.dockercfg ]]; then
  cp /var/run/secrets/openshift.io/push/.dockercfg /root/.dockercfg
fi
if [[ -f /root/pushsecret/.dockercfg ]] && [[ ! -e /root/.dockercfg ]]; then
  cp /root/pushsecret/.dockercfg /root/.dockercfg
fi


for TAG in "${NEW_TAGS[@]}";do
  log_info "Tagging $SRC_IMAGE with new tag: $TAG"
  oc tag $SRC_IMAGE $BUILD_IMAGE:$TAG -n $BUILD_NAMESPACE

  if [ "$PUSH_TO_DOCKER" = "y" ];then
    log_info "Pushing tag directly to docker registry"
    docker tag $UPSTREAM_IMAGE $UPSTREAM_IMAGE_NAME:$TAG
    docker push $UPSTREAM_IMAGE_NAME:$TAG
  fi
done
