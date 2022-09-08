
# base image (amd64)
# FROM alpine:3.16.2@sha256:1304f174557314a7ed9eddb4eab12fed12cb0cd9809e4c28f29af86979a3c870
# base image (arm64/v8)
FROM alpine:3.16.2@sha256:ed73e2bee79b3428995b16fce4221fc715a849152f364929cdccdc83db5f3d5c

# args
ARG GCLOUD_SDK_VERSION=399.0.0
# KUBECTL_VERSION defaults to latest if not specified
ARG KUBECTL_VERSION=v1.25.0

ARG GIT_USERNAME
ARG GIT_TOKEN

# install additional packages
RUN apk update && \
	apk --no-cache add \
		bash \
		curl \
		jq \
		gettext \
		python3 \
		py3-crcmod \
		py3-openssl \
		libc6-compat \
		openssh-client \
		git \
		gnupg \
		ca-certificates \
		tzdata \
	&& rm -rf /var/cache/apk/*

# set current dir
WORKDIR /usr/local/bin

# install gcloud sdk
RUN if [ `uname -m` = 'x86_64' ]; then echo -n "x86_64" > /tmp/gcloud-arch; else echo -n "arm" > /tmp/gcloud-arch; fi;
RUN GCLOUD_ARCH=`cat /tmp/gcloud-arch` && \
	curl -sLO https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-${GCLOUD_ARCH}.tar.gz && \
	tar xzf google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-${GCLOUD_ARCH}.tar.gz && \
	rm google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-${GCLOUD_ARCH}.tar.gz && \
	ln -s ./google-cloud-sdk/bin/gcloud ./gcloud && \
	ln -s ./google-cloud-sdk/bin/gsutil ./gsutil && \
	gcloud config set core/disable_usage_reporting true && \
	gcloud config set component_manager/disable_update_check true && \
	gcloud config set metrics/environment github_docker_image && \
	mkdir -p /.config/gcloud && \
	chown 1001 /.config/gcloud

# install kubectl
RUN if [ `uname -m` = 'x86_64' ]; then echo -n "amd64" > /tmp/kubectl-arch; else echo -n "arm64" > /tmp/kubectl-arch; fi;
RUN if [ -z ${KUBECTL_VERSION} ]; then curl -sL https://dl.k8s.io/release/stable.txt > /tmp/kubectl-version; else echo -n ${KUBECTL_VERSION} > /tmp/kubectl-version; fi;
RUN KUBECTL_ARCH=`cat /tmp/kubectl-arch` && \
	KUBECTL_DOWN_VERSION=`cat /tmp/kubectl-version` && \
	curl -sLO https://dl.k8s.io/release/${KUBECTL_DOWN_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl && \
	chmod +x kubectl

# set current dir
WORKDIR /tmp

# setting folders and files permissions to uid 1001

# set user
USER 1001:1001

# entrypoint
ENTRYPOINT ["/bin/sh", "-c", "while :; do echo 'I go to sleep for a bit, see you later...'; sleep 3600; done"]
