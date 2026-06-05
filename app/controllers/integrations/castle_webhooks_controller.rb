# frozen_string_literal: true

# Module including things related to integrations with other services
module Integrations
  # Controller for receiving Castle incoming webhooks
  class CastleWebhooksController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :verify_authenticity_token

    before_action :verify_request, only: %i[create]

    # Shows last 50 webhooks payload details
    # @note This should not be in the production, but for this app it is presented for
    # you to learn and play with it
    def index
      @castle_webhooks = Integrations::CastleWebhook.recent
    end

    # Stores locally webhook details that were sent by Castle
    def create
      # We don't use #params here because Rails adds some extra details that aren't from Castle
      # during the #params building process
      CastleWebhook.create!(body: JSON.parse(request_body))
    end

    private

    # @return [String] raw request body
    def request_body
      @request_body ||= begin
        # We don't know the state of the IO for body, so we rewind it just in case
        # and we do the same after reading it, so it can be read again
        request.body.rewind
        body = request.body.read
        request.body.rewind
        body
      end
    end

    # Verifies that the incoming request comes from Castle by checking the
    # X-Castle-Signature header against the raw body using the SDK helper.
    # @note We trigger ActionController::RoutingError to notify any invalid request sender that
    #   an endpoint like that does not exist
    # @raise [ActionController::RoutingError] routing error if it was not castle request
    def verify_request
      raise ActionController::RoutingError, 'Not found' if request.headers['X-Castle-Signature'].blank?

      Castle::Webhooks::Verify.call(request)
    rescue Castle::Error
      raise ActionController::RoutingError, 'Not found'
    end
  end
end
