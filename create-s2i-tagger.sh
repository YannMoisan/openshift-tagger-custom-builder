#!/bin/bash

if [ -z "$NAME" ]; then
  echo "Please define NAME for this tagger build"
  exit 1
fi

if [ -z "$BUILD_IMAGE" ]; then
  echo "Please define BUILD_IMAGE for this tagger build"
  exit 2
fi

if [ -z "$SCMSECRET" ]; then
  echo "Please define SCMSECRET for this application"
  exit 3
fi

if [ -z "$OC_SECRET" ]; then
  echo "Please define OC_SECRET for this application"
  exit 4
fi

NAMESPACE=$(oc project --short)

read -p "Creading $NAME that will tag $BUILD_IMAGE in project $NAMESPACE. Press any key to continue..." -n 1 -r

oc process -f openshift-s2i-tagger.json  \
    -p NAME=$NAME \
    -p BUILD_NAMESPACE=$NAMESPACE \
    -p SCMSECRET=$SCMSECRET \
    -p MEMORY_LIMIT=256Mi \
    -p BUILD_IMAGE=$BUILD_IMAGE \
    -p OC_SECRET=$OC_SECRET \
    | oc create -f -	


