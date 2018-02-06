FROM openshift/origin:v3.7.1

MAINTAINER Yann Moisan <yamo93@gmail.com>

LABEL io.k8s.description="Custom Image Builder" \
      io.k8s.display-name="Custom Builder" \
      io.openshift.tags="builder,custom"

RUN echo "Installing Build Tools" && \
    yum install -y http://mirror.onet.pl/pub/mirrors/fedora/linux/epel//epel-release-latest-7.noarch.rpm && \
    yum install -y --enablerepo=centosplus gettext automake make docker jq && \
    yum clean all -y

ENV HOME /root

ADD ./build.sh /tmp/build.sh

ENTRYPOINT [ "/bin/sh", "-c" ]

CMD [ "/tmp/build.sh" ]
