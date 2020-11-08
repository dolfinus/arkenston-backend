#!/bin/bash
set -e

./wait_for_postgres.sh
REPLACE_OS_VARS=true bin/arkenston foreground "$@"
