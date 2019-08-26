#!/bin/bash

./wait_for_postgres.sh
#REPLACE_OS_VARS=true _build/$MIX_ENV/rel/arkenston/bin/arkenston seed
REPLACE_OS_VARS=true _build/$MIX_ENV/rel/arkenston/bin/arkenston foreground