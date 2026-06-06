# frozen_string_literal: true

module Users
  # Demonstrates the Privacy API (GDPR/CCPA): request or delete user data for a
  # given identifier.
  class PrivacyController < ApplicationController
    # Renders the form (and any result from a previous POST).
    def show; end

    # Calls the request- or delete-user-data endpoint depending on which button
    # was used, echoing the Castle response.
    def create
      @payload = {
        identifier: params[:identifier].presence || current_user.email,
        identifier_type: params[:identifier_type].presence || '$email'
      }
      @action = params[:commit_action] == 'delete' ? 'delete' : 'request'

      @result =
        if @action == 'delete'
          castle.delete_user_data(@payload)
        else
          castle.request_user_data(@payload)
        end
    rescue Castle::Error => e
      @error = e.message
    ensure
      render :show
    end
  end
end
