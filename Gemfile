# frozen_string_literal: true

source 'https://rubygems.org'

ruby file: '.ruby-version'

gem 'bootsnap', require: false
# Test against the tagged 9.2.0 release before it lands on RubyGems.
# Once published, switch back to the registry version: gem 'castle-rb', '~> 9.2'
gem 'castle-rb', github: 'castle/castle-ruby', tag: 'v9.2.0'
gem 'devise', '~> 5.0'
gem 'dotenv-rails'
gem 'hamlit-rails'
gem 'puma', '~> 6.4'
gem 'rails', '~> 8.1.3'
gem 'responders'
gem 'simple_form'
gem 'sprockets-rails'
gem 'sqlite3', '~> 2.1'
gem 'tailwindcss-rails', '~> 3.3'

group :development, :test do
  gem 'byebug'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'simplecov', require: false
end

group :development do
  gem 'web-console'
end
