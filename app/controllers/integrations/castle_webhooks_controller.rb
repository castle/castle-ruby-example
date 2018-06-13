# frozen_string_literal: true

require 'integrations/castle_webhook_verifier'

# Module including things related to integrations with other services
# @note This does not apply to oauth as oauth is in the user scope to indicate its
#   relationship with the user
module Integrations
  # Controller for receiving Castle incoming webhooks
  class CastleWebhooksController < ApplicationController
    skip_before_action :authenticate_user!
    before_action :verify_request

    # Stores locally webhook details
    def create
      # We don't use #params here because Rails adds some extra details that aren't from Castle
      # during the #params building process
      CastleWebhook.create!(body: JSON.parse(request_body))
    end

    private

    def request_body
      @request_body ||= begin
        # We don't know the state of the IO for body, so we rewind it just in case
        # and we do the same after reading it, so it can be read again
        request.body.rewind
        body = request.body.read
        request.body.rewind
      end
    end

    def verify_request
      return if CastleWebhookVerifier.valid?(
        request_body,
        # We have to cast to string, in case it is nil. If signature is nil, it means
        # that something is not right and the verifier expects string
        headers['X-Castle-Signature'].to_s
      )

      raise ActionController::RoutingError
    end
  end
end
