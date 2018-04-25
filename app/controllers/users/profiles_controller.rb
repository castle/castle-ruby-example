# frozen_string_literal: true

module Users
  class ProfilesController < ApplicationController
    layout 'devise'

    after_action :track_profile_update, only: :update

    def update
      current_user.update_without_password(user_params)
      respond_with current_user, location: root_path
    end

    private

    def user_params
      params.require(:user).permit(:email)
    end

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
