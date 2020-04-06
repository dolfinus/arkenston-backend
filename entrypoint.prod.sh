#!/bin/bash
set -e

./wait_for_postgres.sh
REPLACE_OS_VARS=true _build/$MIX_ENV/rel/arkenston/bin/arkenston foreground
