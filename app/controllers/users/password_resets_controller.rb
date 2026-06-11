# frozen_string_literal: true

module Users
  # Demonstrates recording a password reset. We assume the user already passed
  # the reset challenge (e.g. an emailed OTP) and record the outcome with the
  # non-blocking `log` endpoint. The password is not actually changed.
  class PasswordResetsController < ApplicationController
    # Renders the form (and any result from a previous POST).
    def show; end

    # Reusing the current password counts as a failed reset; any other value is
    # a successful one. Either way we only log the event to Castle.
    def create
      status = current_user.valid_password?(params[:password].to_s) ? '$failed' : '$succeeded'

      payload = {
        type: '$password_reset',
        status: status,
        request_token: castle_request_token,
        user: { id: current_user.id.to_s, email: current_user.email }
      }
      result = castle.log(**payload)
      record_castle_result(endpoint: 'log', payload: payload, response: result)
    rescue Castle::Error => e
      record_castle_result(endpoint: 'log', payload: payload, error: e)
    ensure
      render :show
    end
  end
end
