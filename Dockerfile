FROM openshift/origin-base

MAINTAINER Yann Moisan <yamo93@gmail.com>

LABEL io.k8s.description="Custom Image Builder" \
      io.k8s.display-name="Custom Builder" \
      io.openshift.tags="builder,custom"

RUN echo "Installing Build Tools" && \
    yum install -y --enablerepo=centosplus gettext automake make docker jq && \
    yum clean all -y

RUN wget https://github.com/openshift/origin/releases/download/v1.1.1/openshift-origin-client-tools-v1.1.1-e1d9873-linux-64bit.tar.gz && \
    tar xvzf openshift-origin-client-tools-v1.1.1-e1d9873-linux-64bit.tar.gz

WORKDIR /openshift-origin-client-tools-v1.1.1-e1d9873-linux-64bit

ENV HOME /root

ADD ./build.sh /tmp/build.sh

CMD [ "/tmp/build.sh" ]
