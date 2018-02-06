# Tagger Custom Builder

Support multiple tags for a build output

This can be hacked together today by:

1) create a custom builder image that pulls the built image and re-tags it with the commit found in the image label and pushes it
2) define a custom build config with an image change trigger such that it gets run whenever the "real" build pushes a new image.

cf https://trello.com/c/nOX8FTRq/686-5-support-multiple-tags-for-a-build-output

## How it works

## Run it locally

```
docker run -it -e TOKEN=$(oc whoami -t) \
               -e OPENSHIFT_INSTANCE=<…> \
               -e BUILD_NAMESPACE=<…> \
               -e BUILD_IMAGE=<…> \
               yamo/openshift-tagger-custom-builder
```

## Use it on openshift

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

You need to also assign a proper role for `builder` serviceaccount to allow
reading and modifying imagestreams. You can use `edit` role:

```
oc adm policy add-role-to-user edit -z builder
```
