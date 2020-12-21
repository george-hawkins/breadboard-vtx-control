FROM ubuntu:focal

# Betaflight Ubuntu build instructions: https://github.com/betaflight/betaflight/blob/master/docs/development/Building%20in%20Ubuntu.md

RUN apt-get update && apt-get install -y curl git build-essential python3 python-is-python3

WORKDIR /betaflight

# To install Docker - https://docs.docker.com/engine/install/ubuntu/
# Complete the post-install step to use without `sudo` - https://docs.docker.com/engine/install/linux-postinstall/
# You _don't_ need to configure Docker to start on boot - it will be started when needed when you use Docker.
#
# To use this Dockerfile - build the Docker image:
#
# $ docker build . -t betaflight
#
# Then use it:
#
# $ docker run --rm --volume $PWD:/betaflight betaflight:latest make arm_sdk_install
# $ docker run --rm --volume $PWD:/betaflight betaflight:latest make clean TARGET=MATEKF405
# $ docker run --rm --volume $PWD:/betaflight betaflight:latest make hex TARGET=MATEKF405
#
# Or make all three targets in one step:
#
# $ docker run --rm --volume $PWD:/betaflight betaflight:latest make arm_sdk_install clean hex TARGET=MATEKF405
#
# Using `--rm` should mean images don't accumulate but, for whatever reason, this can still happen. Check with:
#
# $ docker image ls
#
# Clean up with:
#
# $ docker system prune
#
# TODO: if you want to avoid specifying the volume on the command line and want to specify the user and group (rather than root) use docker compose. See:
#
# * https://stackoverflow.com/a/47942216/245602
# * https://stackoverflow.com/a/56904335/245602
