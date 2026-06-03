# frozen_string_literal: true

module Users
  # Sends an ad-hoc custom event to Castle for the signed-in user. Custom events
  # are only meaningful once a user is authenticated, so this lives behind the
  # default `authenticate_user!` before_action.
  class CustomEventsController < ApplicationController
    layout 'devise'

    # Records a custom event with the non-blocking log endpoint.
    def create
      castle.log(
        type: '$custom',
        name: 'Demo custom event',
        status: '$succeeded',
        request_token: castle_request_token,
        user: { id: current_user.id, email: current_user.email }
      )
    rescue Castle::Error
      nil
    ensure
      redirect_to edit_users_profile_path, notice: t('.sent')
    end
  end
end
