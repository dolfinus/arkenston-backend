#!/bin/bash

set -e

./wait_for_postgres.sh
mix ecto.setup

if [[ "x$GENERATE_DOCS" == "xtrue" ]]; then
  mix graphql.dump
  mix graphql.docs
fi

mkdir -p ./_build && chown arkenston:arkenston -R ./_build
sudo -u arkenston -E mix phx.server
