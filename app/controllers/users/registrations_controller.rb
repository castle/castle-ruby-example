# frozen_string_literal: true

module Users
  # User registration Devise actions
  class RegistrationsController < Devise::RegistrationsController
    layout 'devise'
  end
end
