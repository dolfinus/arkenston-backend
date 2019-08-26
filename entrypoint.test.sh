#!/bin/bash

./wait_for_postgres.sh
mix ecto.setup
mix test