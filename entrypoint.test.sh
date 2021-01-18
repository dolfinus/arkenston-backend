#!/bin/bash

set -e

./wait_for_postgres.sh;

if [ ! -z "$CI" ]; then
  mix coverage --pro $@;
else
  case "$*" in
    *-h*)
      mix help espec;
      exit 0;
      ;;
    *--help*)
      mix help espec;
      exit 0;
      ;;
    *)
      mix test "$@";
      ;;
  esac
fi

if [ ! -z "$CI" ]; then
  mix quality.ci;
else
  mix quality;
fi

mix absinthe.schema;
