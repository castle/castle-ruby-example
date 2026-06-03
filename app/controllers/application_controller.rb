# frozen_string_literal: true

require 'application_responder'
require 'castle/support/rails'

# Main application controller
class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder
  respond_to :html

  protect_from_forgery with: :exception

  before_action :authenticate_user!

  private

  # The request token is minted client-side by the Castle browser SDK and
  # submitted in a hidden field. It ties the browser fingerprint to the
  # server-side risk/filter call.
  # @return [String, nil]
  def castle_request_token
    params[:castle_request_token]
  end
end
