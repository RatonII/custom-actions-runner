FROM public.ecr.aws/debian/debian:bullseye-slim

COPY --from=gcr.io/kaniko-project/executor /kaniko/executor /kaniko/executor
COPY --from=gcr.io/kaniko-project/executor /kaniko/docker-credential-gcr /kaniko/docker-credential-gcr
COPY --from=gcr.io/kaniko-project/executor /kaniko/docker-credential-ecr-login /kaniko/docker-credential-ecr-login
COPY --from=gcr.io/kaniko-project/executor /kaniko/docker-credential-acr-env /kaniko/docker-credential-acr-env
COPY --from=gcr.io/kaniko-project/executor /kaniko/.docker /kaniko/.docker
#COPY files/nsswitch.conf /etc/nsswitch.conf

ARG ARCH=x64
ARG RUNNER_VERSION=2.299.1
ARG RUNNER_CONTAINER_HOOKS_VERSION=0.1.3
# Docker and Docker Compose arguments
ARG DUMB_INIT_VERSION=1.2.5
ARG RUNNER_USER_UID=1001

ENV DEBIAN_FRONTEND=noninteractive
ENV DOCKER_CONFIG /kaniko/.docker/
ENV DOCKER_CREDENTIAL_GCR_CONFIG /kaniko/.config/gcloud/docker_credential_gcr_config.json

RUN apt-get update -y \
    && apt-get install -y software-properties-common \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    git-lfs \
    unzip \
    wget


#RUN adduser --disabled-password --gecos "" --uid $RUNNER_USER_UID runner \
#    && groupadd docker --gid $DOCKER_GROUP_GID \
#    && usermod -aG sudo runner \
#    && usermod -aG docker runner \
#    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers \
#    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers

ENV HOME=/runner

RUN wget https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_x86_64 -O /usr/bin/dumb-init\
    && chmod +x /usr/bin/dumb-init

ENV RUNNER_ASSETS_DIR=/runnertmp
RUN mkdir -p "$RUNNER_ASSETS_DIR" \
    && cd "$RUNNER_ASSETS_DIR" \
    && wget https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -O runner.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz \
    && ./bin/installdependencies.sh \
    && mv ./externals ./externalstmp \
    # libyaml-dev is required for ruby/setup-ruby action.
    # It is installed after installdependencies.sh and before removing /var/lib/apt/lists
    # to avoid rerunning apt-update on its own.
    && apt-get install -y libyaml-dev \
    && rm -rf /var/lib/apt/lists/*

ENV RUNNER_TOOL_CACHE=/opt/hostedtoolcache
RUN mkdir /opt/hostedtoolcache
#    && chgrp docker /opt/hostedtoolcache \
#    && chmod g+rwx /opt/hostedtoolcache

RUN cd "$RUNNER_ASSETS_DIR" \
    && wget https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip -O runner-container-hooks.zip\
    && unzip ./runner-container-hooks.zip -d ./k8s \
    && rm -f runner-container-hooks.zip

#RUN set -vx; \
#    export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
#    && if [ "$ARCH" = "arm64" ]; then export ARCH=aarch64 ; fi \
#    && if [ "$ARCH" = "amd64" ] || [ "$ARCH" = "i386" ]; then export ARCH=x86_64 ; fi \
#    && curl -fLo docker.tgz https://download.docker.com/linux/static/${CHANNEL}/${ARCH}/docker-${DOCKER_VERSION}.tgz \
#    && tar zxvf docker.tgz \
#    && install -o root -g root -m 755 docker/docker /usr/bin/docker \
#    && rm -rf docker docker.tgz

#RUN export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
#    && if [ "$ARCH" = "arm64" ]; then export ARCH=aarch64 ; fi \
#    && if [ "$ARCH" = "amd64" ] || [ "$ARCH" = "i386" ]; then export ARCH=x86_64 ; fi \
#    && curl -fLo /usr/bin/docker-compose https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-${ARCH} \
#    && chmod +x /usr/bin/docker-compose

# We place the scripts in `/usr/bin` so that users who extend this image can
# override them with scripts of the same name placed in `/usr/local/bin`.
COPY entrypoint.sh startup.sh logger.sh graceful-stop.sh update-status /usr/bin/
RUN chmod +x /usr/bin/*
# Copy the docker shim which propagates the docker MTU to underlying networks
# to replace the docker binary in the PATH.
#COPY docker-shim.sh /usr/local/bin/docker

# Configure hooks folder structure.
COPY hooks /etc/arc/hooks/

ENV ImageOS=debian-bullseye-slim

RUN echo "PATH=${PATH}" > /etc/environment \
    && echo "ImageOS=${ImageOS}" >> /etc/environment \
WORKDIR /runner
#USER runner
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["entrypoint.sh"]
