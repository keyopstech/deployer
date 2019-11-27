# Download skaffold
FROM alpine:3.10 as download-skaffold
ENV SKAFFOLD_VERSION 1.0.1
ENV SKAFFOLD_URL https://storage.googleapis.com/skaffold/releases/v${SKAFFOLD_VERSION}/skaffold-linux-amd64
RUN wget -O skaffold "${SKAFFOLD_URL}"
RUN chmod +x skaffold

# Download kubectl
FROM alpine:3.10 as download-kubectl
ENV KUBECTL_VERSION v1.16.0
ENV KUBECTL_URL https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
RUN wget -O kubectl "${KUBECTL_URL}"
RUN chmod +x kubectl

# Download helm
FROM alpine:3.10 as download-helm
ENV HELM_VERSION v2.13.0
ENV HELM_URL https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz
RUN wget -O helm.tar.gz "${HELM_URL}"
RUN tar -xvf helm.tar.gz --strip-components 1

# Download kustomize
FROM alpine:3.10 as download-kustomize
ENV KUSTOMIZE_VERSION 3.2.0
ENV KUSTOMIZE_URL https://github.com/kubernetes-sigs/kustomize/releases/download/v${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64
RUN wget -O kustomize "${KUSTOMIZE_URL}"
RUN chmod +x kustomize

# Download kompose
FROM alpine:3.10 as download-kompose
ENV KOMPOSE_VERSION v1.19.0
ENV KOMPOSE_URL https://github.com/kubernetes/kompose/releases/download/${KOMPOSE_VERSION}/kompose-linux-amd64
RUN wget -O kompose "${KOMPOSE_URL}"
RUN chmod +x kompose

# Download container-structure-test
FROM alpine:3.10 as download-container-structure-test
ENV CONTAINER_STRUCTURE_TEST_VERSION v1.5.0
ENV CONTAINER_STRUCTURE_TEST_URL https://storage.googleapis.com/container-structure-test/${CONTAINER_STRUCTURE_TEST_VERSION}/container-structure-test-linux-amd64
RUN wget -O container-structure-test "${CONTAINER_STRUCTURE_TEST_URL}"
RUN chmod +x container-structure-test

# Download kind
FROM alpine:3.10 as download-kind
ENV KIND_VERSION v0.6.0
ENV KIND_URL https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64
RUN wget -O kind "${KIND_URL}"
RUN chmod +x kind

# Download gcloud
FROM alpine:3.10 as download-gcloud
ENV GCLOUD_VERSION 271.0.0
ENV GCLOUD_URL https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz
RUN wget -O gcloud.tar.gz "${GCLOUD_URL}"
RUN tar -zxf gcloud.tar.gz

# Download pack
FROM alpine:3.10 as download-pack
ENV PACK_VERSION 0.5.0
ENV PACK_URL https://github.com/buildpack/pack/releases/download/v${PACK_VERSION}/pack-v${PACK_VERSION}-linux.tgz
RUN wget -O pack.tgz "${PACK_URL}"
RUN tar -zxf pack.tgz

FROM alpine:3.10 as runtimes

# Install tools
RUN apk add --no-cache \
        sudo \
        wget \
        curl \
        ca-certificates \
        python \
        py-pip \
        openssl \
        openssh \
        bash \
        git \
        unzip

# Install Ansible
RUN apk add --no-cache --virtual .build-dependencies \
        python-dev \
        libffi-dev \
        openssl-dev \
        build-base \
    && pip install --upgrade pip cffi ansible requests google-auth \
    && apk del .build-dependencies

COPY --from=docker:18.09.6 /usr/local/bin/docker /usr/local/bin/
COPY --from=download-skaffold skaffold /usr/local/bin/
COPY --from=download-kubectl kubectl /usr/local/bin/
COPY --from=download-helm helm /usr/local/bin/
COPY --from=download-kustomize kustomize /usr/local/bin/
COPY --from=download-kompose kompose /usr/local/bin/
COPY --from=download-container-structure-test container-structure-test /usr/local/bin/
COPY --from=download-kind kind /usr/local/bin/
COPY --from=download-gcloud google-cloud-sdk/ /google-cloud-sdk/
COPY --from=download-pack pack /usr/local/bin/

# Finish installation of gcloud
RUN CLOUDSDK_PYTHON="python2.7" /google-cloud-sdk/install.sh \
    --usage-reporting=false \
    --bash-completion=false \
    --disable-installation-options

ENV PATH=$PATH:/google-cloud-sdk/bin
RUN gcloud auth configure-docker