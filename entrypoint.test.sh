#!/bin/bash

set -e

./wait_for_postgres.sh
mix test
mix dialyzer
