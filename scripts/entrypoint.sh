#!/bin/bash

set -x

# Expect version number under $1
RUNNER_VERSION=`cat /runner_version.env`
echo "RUNNER VERSION: ${RUNNER_VERSION}"

# Identify owner, repo and token
GH_OWNER=$GH_OWNER
GH_REPOSITORY=$GH_REPOSITORY
GH_TOKEN=$GH_TOKEN

# Setup the runner if not already done
# && echo "${RUNNER_HASH} actions-runner-linux-${RUNNER_PLATFORM}-${RUNNER_VERSION}.tar.gz" | shasum -a 256 -c \
if [ ! -d /home/docker/actions-runner ]; then
  mkdir -p /home/docker/actions-runner-linux-x64
  mkdir -p /home/docker/actions-runner-linux-arm
  mkdir -p /home/docker/actions-runner-linux-arm64

  cd /home/docker/actions-runner-linux-x64
  curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
      && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

  cd /home/docker/actions-runner-linux-arm
  curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm-${RUNNER_VERSION}.tar.gz \
      && tar xzf ./actions-runner-linux-arm-${RUNNER_VERSION}.tar.gz

  cd /home/docker/actions-runner-linux-arm64
  curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz \
      && tar xzf ./actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz

  cd /home/docker
  PLATFORM=`uname -m`
  echo PLATFORM="$PLATFORM"
  if [ "${PLATFORM}" = "aarch" ]; then
    ln -s actions-runner-linux-arm actions-runner
  elif [ "${PLATFORM}" = "aarch64" ]; then
    ln -s actions-runner-linux-arm64 actions-runner
  else
    ln -s actions-runner-linux-x64 actions-runner
  fi

  # install some additional dependencies
  chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh
fi


# Go for the runner
RUNNER_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)
RUNNER_NAME="dockerNode-${RUNNER_SUFFIX}"

REG_TOKEN=$(curl -sX POST -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GH_TOKEN}" https://api.github.com/repos/${GH_OWNER}/${GH_REPOSITORY}/actions/runners/registration-token | jq .token --raw-output)

cd /home/docker/actions-runner

./config.sh --unattended --url https://github.com/${GH_OWNER}/${GH_REPOSITORY} --token ${REG_TOKEN} --name ${RUNNER_NAME}

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
