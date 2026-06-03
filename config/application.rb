# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Example app namespace
module CastleExample
  # Rails app
  class Application < Rails::Application
    config.load_defaults 8.1

    # This example app doesn't ship encrypted credentials. Outside production we
    # read the secret from the environment (with a static fallback) so boot never
    # depends on a master key; production still requires SECRET_KEY_BASE.
    unless Rails.env.production?
      config.secret_key_base = ENV.fetch('SECRET_KEY_BASE', 'castle_example_dev_test_secret_key_base')
    end
  end
end
