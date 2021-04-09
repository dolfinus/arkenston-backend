#!/bin/bash

set -e

./wait_for_postgres.sh
mix ecto.setup

mkdir -p ./_build && chown arkenston:arkenston -R ./_build
elixir --sname arkenston@localhost -S mix phx.server "$@"