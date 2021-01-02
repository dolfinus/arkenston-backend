#!/bin/bash

set -e

ENV="$1"
shift
COMMAND="$@"

if [[ "x$ENV" == "x" ]]
then
  ENV="prod"
fi

if [[ "x$COMMAND" == "x" ]]
then
  COMMAND="up --build"
fi

docker build -t dolfinus/arkenston-backend:base -f Dockerfile.base .
docker-compose -p "arkenston-${ENV}" -f "docker-compose.$ENV.yml" $COMMAND
