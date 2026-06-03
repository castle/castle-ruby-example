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
    # log endpoint, noting whether the change was valid.
    def track_profile_update
      status = current_user.valid? ? '$succeeded' : '$failed'

      castle.log(
        type: '$profile_update',
        status: status,
        user: { id: current_user.id, email: current_user.email }
      )
    rescue Castle::Error
      nil
    end
  end
end
