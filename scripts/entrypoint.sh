#!/bin/bash
#
echo "Docker GitHub self-hosted runner as Linux container"

# Expect version number under $1
RUNNER_VERSION=`cat /runner_version.env`

# Identify owner, repo and token
GH_OWNER=$GH_OWNER
GH_REPOSITORY=$GH_REPOSITORY
GH_TOKEN=$GH_TOKEN

# Setup the runner if not already done
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
echo "Changing permissions docker:docker to ./actions-runner"
chown -R docker:docker /home/docker/actions-runner

# Go for the runner
echo "Starting the runner"
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
