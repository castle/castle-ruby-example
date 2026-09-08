# frozen_string_literal: true

module Users
  # Demonstrates assessing a completed password reset. We assume the user
  # already passed the reset challenge (e.g. an emailed OTP). The password is
  # not actually changed.
  class PasswordResetsController < ApplicationController
    # Renders the form (and any result from a previous POST).
    def show; end

    # Reusing the current password counts as a failed reset; any other value is
    # a successful one.
    def create
      status = current_user.valid_password?(params[:password].to_s) ? '$failed' : '$succeeded'

      payload = {
        type: '$profile_reset',
        status: status,
        request_token: castle_request_token,
        user: { id: current_user.id.to_s, email: current_user.email }
      }
      payload[:changeset] = { password: { changed: true } } if status == '$succeeded'
      result = castle.risk(**payload)
      record_castle_result(endpoint: 'risk', payload: payload, response: result)
    rescue Castle::Error => e
      record_castle_result(endpoint: 'risk', payload: payload, error: e)
    ensure
      render :show
    end
  end
end
