# frozen_string_literal: true

module Users
  # Demonstrates the Privacy API (GDPR/CCPA): request or delete user data for a
  # given identifier.
  class PrivacyController < ApplicationController
    # Renders the form (and any result from a previous POST).
    def show; end

    # Calls the request- or delete-user-data endpoint depending on which button
    # was used, recording the Castle response.
    def create
      payload = {
        identifier: params[:identifier].presence || current_user.email,
        identifier_type: params[:identifier_type].presence || '$email'
      }

      if params[:commit_action] == 'delete'
        result = castle.delete_user_data(payload)
        endpoint = 'privacy (delete)'
      else
        result = castle.request_user_data(payload)
        endpoint = 'privacy (request)'
      end

      record_castle_result(endpoint: endpoint, payload: payload, response: result)
    rescue Castle::Error => e
      record_castle_result(endpoint: 'privacy', payload: payload, error: e)
    ensure
      render :show
    end
  end
end
