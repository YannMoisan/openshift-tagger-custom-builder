FROM openshift/origin:v3.7.1

LABEL io.k8s.description="Custom Image Builder used for tagging based on commit id" \
      io.k8s.display-name="Custom Builder" \
      io.openshift.tags="builder,custom"

RUN echo "Installing Build Tools" && \
    yum install -y http://mirror.onet.pl/pub/mirrors/fedora/linux/epel/epel-release-latest-7.noarch.rpm && \
    yum install -y --enablerepo=centosplus gettext automake make docker jq && \
    yum clean all -y

ENV HOME /root

COPY ./build.sh /tmp/build.sh
RUN chmod +x /tmp/build.sh

ENTRYPOINT [ "/bin/sh", "-c" ]

CMD [ "/tmp/build.sh" ]
