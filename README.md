# OpenShift Tagger Custom Builder

Missing part for OpenShift which adds tags (imagestream and traditional docker) based on commit id for s2i builds.

Support multiple tags for a build output

This can be hacked together today by:

1) create a custom builder image that pulls the built image and re-tags it with the commit found in the image label and pushes it
2) define a custom build config with an image change trigger such that it gets run whenever the "real" build pushes a new image.

cf https://trello.com/c/nOX8FTRq/686-5-support-multiple-tags-for-a-build-output

## How it works
You can use it manually (for testing) or put it in openshift as BuildConfig
chained with source-to-image builds. Tagger build should be chained with single
build using trigger and after upstream s2i job is finished it's launched with
metadata containing upstream image id. Based on it script will fetch data
directly from imagestream, parse labels with commit id info, add tag to
imagestream and optionally push docker tag to source docker registry.

## Run it locally

```
docker run -it -e TOKEN=$(oc whoami -t) \
               -e OPENSHIFT_INSTANCE=<…> \
               -e BUILD_NAMESPACE=<…> \
               -e BUILD_IMAGE=<…> \
               -e SKIP_TLS_VERIFY=y
               cloudowski/openshift-tagger-custom-builder
```

## Use it on openshift

To use it, you just have to add a BuildConfig for your app (APPLICATION_NAME) that will be triggered after your build.

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
          name: cloudowski/openshift-tagger-custom-builder
        pullSecret:
          name: dockercfg
        forcePull: true
        env:
        - name: BUILD_NAMESPACE
          value: ${IMAGESTREAM_NAMESPACE}
        - name: DEBUG
          value: 'n'
        - name: SKIP_TLS_VERIFY
          value: 'y'
        - name: PUSH_TO_DOCKER
          value: 'n'
        - name: CREATE_LONG_TAG
          value: 'n'
        - name: CREATE_SHORT_TAG
          value: 'y'
    triggers:
    - type: ImageChange
    - type: ImageChange
      imageChange:
        from:
          kind: ImageStreamTag
          name: ${APPLICATION_NAME}:latest
```

You need to also assign a proper role for `builder` serviceaccount to allow
reading and modifying imagestream objects. You can use `edit` role:

```
oc adm policy add-role-to-user edit -z builder
```

In [openshift/](openshift/) directory there's a sample file you can use for
testing which uses BuildConfig to also build tagger image.
