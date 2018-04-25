# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    layout 'devise'
  end
end
