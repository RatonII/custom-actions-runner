FROM public.ecr.aws/debian/debian:bookworm-slim

COPY --from=gcr.io/kaniko-project/executor /kaniko/executor /kaniko/executor
COPY --from=gcr.io/kaniko-project/executor /kaniko/docker-credential-gcr /kaniko/docker-credential-gcr
COPY --from=gcr.io/kaniko-project/executor /kaniko/docker-credential-ecr-login /kaniko/docker-credential-ecr-login
COPY --from=gcr.io/kaniko-project/executor /kaniko/docker-credential-acr-env /kaniko/docker-credential-acr-env
COPY --from=gcr.io/kaniko-project/executor /kaniko/.docker /kaniko/.docker
#COPY files/nsswitch.conf /etc/nsswitch.conf

ARG ARCH=x64
ARG RUNNER_VERSION=2.319.1
ARG RUNNER_USER_UID=1001
ARG DOCKER_VERSION=20.10.9

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

ENV HOME=/runner
WORKDIR $HOME

RUN wget https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -O runner.tar.gz \
    && echo "3f6efb7488a183e291fc2c62876e14c9ee732864173734facc85a1bfb1744464  runner.tar.gz" | shasum -a 256 -c \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz
RUN echo 'runner:x:1234:1234:,,,:/runner:/usr/sbin/nologin' >> /etc/passwd
RUN ["chown", "1234:1234", "-R", "/runner"]
USER runner

ENV EPHEMERAL=true
ENV ORG_URL="https://github.com/sliide"
ENV RUNNER_SCOPE="org"
ENV LABELS="kaniko,helm"
ENV ACCESS_TOKEN=""
ENV RUNNER_NAME="kaniko-runner"

CMD ["/runner/config.sh", "--unattended", "--name", "$RUNNER_NAME", "--url", "$ORG_URL", "--token", "$ACCESS_TOKEN", "--labels", "$LABELS"]
CMD ["/runner/run.sh", "--ephemeral"]
