#!/bin/bash
set -euo pipefail

export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export LANGUAGE=C.UTF-8
cd "$(dirname "$0")"

if [ ! "$(docker -v)" ]; then
  curl -sSL get.docker.com | sh
fi

if [ ! "$(docker-compose -v)" ]; then
  DOCKER_COMPOSE_RELEASE=$(curl -sL https://api.github.com/repos/docker/compose/releases/latest)
  DOCKER_COMPOSE_VERSION=$(echo $DOCKER_COMPOSE_RELEASE | sed -Ee 's/.*"tag_name":\s*"([^"]*)".*/\1/')
  sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi