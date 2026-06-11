# frozen_string_literal: true

module Users
  # Profile management with Castle integration
  class ProfilesController < ApplicationController
    layout 'devise'

    after_action :track_profile_update, only: :update

    # Typical update of user data without password requirement
    def update
      current_user.update_without_password(user_params)
      respond_with current_user, location: root_path
    end

    private

    # @return [Hash] user permitted params
    def user_params
      params.require(:user).permit(:email)
    end

    # After action that logs the profile update to Castle with the non-blocking
    # log endpoint, noting whether the change was valid. On the redirecting
    # (successful) path the result is persisted so the next page can show it.
    def track_profile_update
      status = current_user.valid? ? '$succeeded' : '$failed'

      payload = {
        type: '$profile_update',
        status: status,
        request_token: castle_request_token,
        user: { id: current_user.id.to_s, email: current_user.email }
      }
      result = castle.log(**payload)
      record_castle_result(endpoint: 'log', payload: payload, response: result)
    rescue Castle::Error => e
      record_castle_result(endpoint: 'log', payload: payload, error: e)
    ensure
      persist_castle_results if response.redirect?
    end
  end
end
