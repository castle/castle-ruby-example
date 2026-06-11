# frozen_string_literal: true

# Credentials for the pre-seeded demo user, mirroring the fixture used by the
# other Castle example apps. Sourced from the environment so they can be
# overridden, with Devise-valid defaults (the password must be at least 6
# characters for Devise's :validatable module).
module DemoAccount
  module_function

  def email
    ENV.fetch('valid_username', 'clark.kent@dailyplanet.com')
  end

  def name
    ENV.fetch('valid_name', 'Clark Kent')
  end

  def password
    ENV.fetch('valid_password', 'castle1234')
  end

  # A password that does not match the demo user, for the "valid user, bad pw"
  # quick-fill on the login page.
  def invalid_password
    ENV.fetch('invalid_password', 'qwerty')
  end

  # Creates (or refreshes) the demo user so the "valid user + pw" quick-fill on
  # the login page actually signs in.
  def seed!
    user = User.find_or_initialize_by(email: email)
    user.name = name
    user.password = password
    user.password_confirmation = password
    user.save!
    user
  end
end
