# Docker GitHub self-hosted runner as Linux container

Repository for building a self hosted GitHub runner as a Ubuntu linux container

Check also the docker-gh-selfhosted-runner-win repo for building a self hosted GitHub runner as a windows container

## Build

`docker build --build-arg RUNNER_VERSION=2.317.0 --build-arg RUNNER_PLATFORM=arm64 --tag docker-gh-runner-linux .`

## Run

`docker run -e GH_TOKEN='myPatToken' -e GH_OWNER='orgName' -e GH_REPOSITORY='repoName' -d image-name`
