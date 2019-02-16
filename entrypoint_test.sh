#!/bin/bash

export RAILS_ENV=test

./wait_for_postgres.sh

bundle exec rake spec
