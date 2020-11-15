#!/bin/bash

set -e

./wait_for_postgres.sh
if [ -z "$TRAVIS" ]; then
  mix coveralls.travis $*
else
  case "$*" in
    *-h*)
      mix help espec
      exit 0
      ;;
    *--help*)
      mix help espec
      exit 0
      ;;
    *)
      mix test "$*"
      ;;
  esac
fi
mix dialyzer
