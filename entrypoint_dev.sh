#!/bin/bash

export RAILS_ENV=development

./wait_for_postgres.sh

bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed
bundle exec rake graphql:dump

if [ "$GENERATE_DOCS" = 'true' ]; then
  bundle exec rake graphql:docs
fi

bundle exec puma
