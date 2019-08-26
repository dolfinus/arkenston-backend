#!/bin/bash

./wait_for_postgres.sh

mix ecto.setup
if [[ "x$GENERATE_DOCS" == "xtrue" ]]; then
  mix graphql.dump
  mix graphql.docs
fi
sudo -u arkenston -E mix phx.server