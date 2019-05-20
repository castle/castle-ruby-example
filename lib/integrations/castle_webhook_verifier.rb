# frozen_string_literal: true

%w[
  base64
  openssl
].each(&method(:require))

module Integrations
  # Module used to verify that incoming webhook was sent by Castle itself
  module CastleWebhookVerifier
    class << self
      # @param incoming_data [String] incoming raw JSON data string
      # @param incoming_signature [String] X-Castle-Signature value
      # @return [Boolean] true if the incoming webhook request is valid and sent by Castle
      def valid?(incoming_data, incoming_signature)
        expected_signature = Base64.encode64(
          OpenSSL::HMAC.digest(
            OpenSSL::Digest::Digest.new('sha256'),
            Rails.application.secrets.castle_secret,
            incoming_data
          )
        ).strip

        incoming_signature == expected_signature
      end
    end
  end
end
