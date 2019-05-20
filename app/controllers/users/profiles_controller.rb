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

    # After action for tracking user profile update with details on whether
    # it was a successful change or not
    def track_profile_update
      event = current_user.valid? ? 'succeeded' : 'failed'

      castle.track(
        event: "$profile_update.#{event}",
        user_id: current_user.id,
        user_traits: current_user.attributes
      )
    end
  end
end
