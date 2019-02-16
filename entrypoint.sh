#!/bin/bash

export RAILS_ENV=production

./wait_for_postgres.sh

bundle exec rails db:create
bundle exec rails db:migrate

if [[ ! -a seed.lock ]]; then
    bundle exec rails db:seed
    touch seed.lock
fi

bundle exec puma
