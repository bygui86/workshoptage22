
# base image
FROM debian:bullseye

# environment variables
ENV GIT_USERNAME joker
ENV GIT_TOKEN supersecret

# install additional packages
RUN apt-get update -qqy && \
	apt-get install -qqy \
		curl \
		jq \
		gettext \
		gcc \
		python3-dev \
		python3-pip \
		apt-transport-https \
		lsb-release \
		openssh-client \
		git \
		gnupg \
		ca-certificates \
		tzdata \
	&& rm -rf /var/lib/apt/lists/*

# set current dir
WORKDIR /usr/local/bin

# install gcloud sdk
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | tee /usr/share/keyrings/cloud.google.gpg && \
	apt-get update -y && \
	apt-get install google-cloud-sdk -y

# install kubectl
RUN curl -sL https://dl.k8s.io/release/stable.txt | sed 's/v//' > /tmp/kubectl-version && \
	KUBECTL_DOWN_VERSION=`cat /tmp/kubectl-version` && \
	curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
	echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list && \
	apt-get update -qqy && \
	apt-get install -qqy kubectl=${KUBECTL_DOWN_VERSION}-00

# entrypoint
ENTRYPOINT ["/bin/sh", "-c", "while :; do echo 'I go to sleep for a bit, see you later...'; sleep 3600; done"]
