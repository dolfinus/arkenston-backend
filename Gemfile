source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.1'

# Use pg as the database for Active Record
gem 'pg', '~> 0.21'

# Use Puma as the app server
gem 'puma', '~> 3.11'
gem 'listen', '>= 3.0.5', '< 3.2'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'

# Use Clearance for user registration
gem 'clearance'

# Use Pundit for auth policy
gem 'pundit'
gem 'graphql-pundit', github: 'ontohub/graphql-pundit', branch: 'dependabot/bundler/pundit-gte-1.1-and-lt-2.1'

# Use JWT Bearer auth
gem 'jwt'

# Use ActiveStorage for attaching files support
gem 'activestorage'

# Use GraphQL as API endpoint
gem 'graphql'

# Use GraphQL Sugar for DRYing default GraphQL types
gem 'graphql-sugar', github: 'dolfinus/graphql-sugar', branch: 'support-1.8-pundit'

# Use validates_type for validating type of fields while assign value
gem 'validates_type'

# Use PaperTrail for versioning
gem 'paper_trail', '~> 10'
gem 'paper_trail-association_tracking'

# Use ActiveRecord Diff for returning diff between versions
gem 'activerecord-diff'

# Use Globalize for translatable content
gem 'globalize', github: 'globalize/globalize', branch: 'master'
# With versioning support also
gem 'globalize-versioning', github: 'dolfinus/globalize-versioning', branch: 'rails_5x'

# Use Paranoia for destroying models without deleting them
gem 'paranoia'

# Use RailsConfig for beautiful configs
gem 'config'

# Use Seedbank for environmental db seed
gem 'seedbank'

# Use Assignable Values for limiting values assignator depend on roles
gem 'assignable_values'

group :development do
  gem 'graphql-docs'
  gem 'rubocop'
  gem 'rubocop-rspec'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :development, :test do
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails'
  gem 'rspec-mocks'
  gem 'coveralls'
  gem 'simplecov'
  gem 'rspec_junit_formatter'
end
