#!/bin/bash

ENV="$1"
shift
COMMAND="$@"

if [[ "x$ENV" == "x" ]]
then
  ENV="prod"
fi

if [[ "x$COMMAND" == "x" ]]
then
  COMMAND="up -d --build"
fi

docker build -t dolfinus/arkenston-backend:base  -f Dockerfile.base .
docker-compose -f "docker-compose.$ENV.yml" $COMMAND
