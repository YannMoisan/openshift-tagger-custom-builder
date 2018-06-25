# Tagger Custom Builder

Support multiple tags for a build output

This can be hacked together today with a custom build strategy:

1) create a custom builder image that pulls the built image and re-tags it with the commit found in the image label and pushes it.
2) define a custom build config with an image change trigger such that it gets run whenever the "real" build pushes a new image.

Note that custom builds are currently not enabled by default. A work around is to create an s2i build that does the work in the `assemble` script: 

1) import the s2i image that has the script to do the tagging work.
2) define an s2i build that will watch the image stream to tag then apply the tag.

cf https://trello.com/c/nOX8FTRq/686-5-support-multiple-tags-for-a-build-output

## How it works

## Run the Custom build strategy locally

```
docker run -it -e TOKEN=$(oc whoami -t) \
               -e OPENSHIFT_INSTANCE=<…> \
               -e BUILD_NAMESPACE=<…> \
               -e BUILD_IMAGE=<…> \
               yamo/openshift-tagger-custom-builder
```

## Use the Custom build strategy on openshift

To use it, you just have to add a BuildConfig that will be triggered after your build

```
- kind: BuildConfig
  apiVersion: v1
  metadata:
    name: ${APPLICATION_NAME}-tagger
    labels:
      application: ${APPLICATION_NAME}
  spec:
    strategy:
      type: Custom
      customStrategy:
        from:
          # this is the builder image
          kind: DockerImage
          name: yamo/openshift-tagger-custom-builder
        pullSecret:
          name: dockercfg
        forcePull: true
        env:
        - name: OPENSHIFT_INSTANCE
          value: ${OPENSHIFT_SERVER}
        - name: BUILD_NAMESPACE
          value: ${APPLICATION_NAME}
        - name: BUILD_IMAGE
          value: ${APPLICATION_NAME}
    triggers:
    - type: ImageChange
    - type: ImageChange
      imageChange:
        from:
          kind: ImageStreamTag
          name: ${APPLICATION_NAME}:latest
```

## Build s2i image locally

```# build the s2i image
docker build .  -t gitops-openshift -f Dockerfile.s2i
```

## Use the s2i image on Openshift

```#create the openshift secret (note openshift-secrets.env is in .gitignore)
NAME=openshift-secrets ./create-env-secret.sh openshift-secrets.env
#load the template that does the tagging build
OC_SECRET=openshift-secrets BUILD_IMAGE=openshiftbot NAME=openshiftbot-tagger SCMSECRET=scmsecret4 ./create-s2i-tagger.sh
