#!/bin/bash

set -e

./wait_for_postgres.sh
if [ -z "$TRAVIS" ]; then
  mix coveralls.travis "$@"
else
  mix test "$@"
fi
mix dialyzer
