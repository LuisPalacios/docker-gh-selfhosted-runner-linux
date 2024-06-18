# base image
FROM ubuntu:24.04

#input GitHub runner version argument
ARG RUNNER_VERSION
ARG RUNNER_HASH
#ARG RUNNER_PLATFORM
ENV DEBIAN_FRONTEND=noninteractive

LABEL Author="Luis Palacios"
LABEL Email="luis.palacios.derqui@gmail.com"
LABEL GitHub="https://github.com/LuisPalacios"
LABEL BaseImage="ubuntu:24.04"
LABEL RunnerVersion=${RUNNER_VERSION}
LABEL RunnerHash=${RUNNER_HASH}
#LABEL RunnerPlatform=${RUNNER_PLATFORM}

# update the base packages + add a non-sudo user
RUN apt-get update -y && apt-get upgrade -y && useradd -m docker

# install the packages and dependencies along with jq so we can parse JSON (add additional packages as necessary)
RUN apt-get install -y --no-install-recommends \
    curl nodejs wget unzip vim git jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip

# Save the version in an environment file
RUN echo "${RUNNER_VERSION}" > /runner_version.env

# cd into the user directory, download and unzip the github actions runner
# && echo "${RUNNER_HASH} actions-runner-linux-${RUNNER_PLATFORM}-${RUNNER_VERSION}.tar.gz" | shasum -a 256 -c \
RUN cd /home/docker && mkdir actions-runner-linux-x64 && cd actions-runner-linux-x64 \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
RUN cd /home/docker && mkdir actions-runner-linux-arm && cd actions-runner-linux-arm \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-arm-${RUNNER_VERSION}.tar.gz
RUN cd /home/docker && mkdir actions-runner-linux-arm64 && cd actions-runner-linux-arm64 \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz

# # install some additional dependencies
# RUN chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh

# add over the entrypoint.sh script
ADD scripts/entrypoint.sh entrypoint.sh

# make the script executable
RUN chmod +x entrypoint.sh

# set the user to "docker" so all subsequent commands are run as the docker user
USER docker

# set the entrypoint to the entrypoint.sh script
ENTRYPOINT ["./entrypoint.sh"]
