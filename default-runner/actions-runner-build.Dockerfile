FROM public.ecr.aws/debian/debian:bookworm-slim

COPY --from=gcr.io/kaniko-project/executor:debug  /kaniko/executor /kaniko/executor
COPY --from=gcr.io/kaniko-project/executor:debug  /kaniko/docker-credential-gcr /kaniko/docker-credential-gcr
COPY --from=gcr.io/kaniko-project/executor:debug  /kaniko/docker-credential-ecr-login  /kaniko/docker-credential-ecr-login
COPY --from=gcr.io/kaniko-project/executor:debug  /kaniko/docker-credential-ecr-login  /kaniko/docker-credential-ecr-login
COPY --from=gcr.io/kaniko-project/executor:debug  /kaniko/docker-credential-acr-env  /kaniko/docker-credential-acr-env
COPY --from=gcr.io/kaniko-project/executor:debug  /kaniko/.docker /kaniko/.docker
COPY --from=mplatform/manifest-tool:alpine  /manifest-tool /kaniko/manifest-tool
#COPY files/nsswitch.conf /etc/nsswitch.conf

ARG DEBIAN_FRONTEND=noninteractive
ARG ARCH=x64
ARG RUNNER_VERSION=2.322.0
ARG RUNNER_USER_UID=1001
ARG DOCKER_VERSION=20.10.9
ENV DOCKER_CONFIG=/kaniko/.docker/
ENV DOCKER_CREDENTIAL_GCR_CONFIG=/kaniko/.config/gcloud/docker_credential_gcr_config.json
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/kaniko

RUN apt-get update -y \
    && apt-get install -y software-properties-common \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    git-lfs \
    unzip \
    curl \
    wget \
    jq

ENV HOME=/runner
WORKDIR $HOME

RUN export RUNNER_ARCH="arm64" \
    && if [ "$(dpkg --print-architecture)" = "amd64" ]; then export RUNNER_ARCH=x64 ; fi \
    && wget https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz -O runner.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz \
    && ./bin/installdependencies.sh

# We pre-install nodejs to reduce time of setup-node and improve its reliability.
ENV NODE_VERSION=20.9.0

RUN if [ "$(dpkg --print-architecture)" = "amd64" ]; then export NODE_ARCH=x64 ; else export NODE_ARCH="arm64" ; fi; \
    mkdir -p /node/${NODE_VERSION}/${NODE_ARCH} && \
    curl -s -L https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.gz \
    | tar xvzf - --strip-components=1 -C /node/${NODE_VERSION}/${NODE_ARCH} \
    && cp -rf /node/${NODE_VERSION}/${NODE_ARCH}/bin/node /usr/bin/node \
    && node --version

RUN echo 'runner:x:1234:1234:,,,:/runner:/usr/sbin/nologin' >> /etc/passwd && \
    echo 'messagebus:x:1111:' >> /etc/group
RUN ["chown", "1234:1234", "-R", "/runner"]
RUN ["chown", "1234:1234", "-R", "/kaniko"]

ENV EPHEMERAL=""
ENV ORG_URL="https://github.com/sliide"
ENV RUNNER_SCOPE="org"
ENV LABELS="kaniko,helm"
ENV ACCESS_TOKEN=$ACCESS_TOKEN

COPY entrypoint.sh  $HOME
RUN chmod +x $HOME/entrypoint.sh
#USER runner
ENV RUNNER_ALLOW_RUNASROOT=true
ENV EPHEMERAL=""
ENV ORG_URL="https://github.com/sliide"
ENV RUNNER_SCOPE="org"
ENV LABELS="kaniko,helm"
ENV ACCESS_TOKEN=$ACCESS_TOKEN

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/runner/entrypoint.sh" ]
