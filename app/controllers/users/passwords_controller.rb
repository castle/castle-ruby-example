# frozen_string_literal: true

module Users
  # Devise password management
  class PasswordsController < Devise::PasswordsController
    layout 'devise'
  end
end
