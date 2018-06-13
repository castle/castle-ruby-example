# frozen_string_literal: true

module Integrations
  class CastleWebhook < ApplicationRecord
    self.table_name = :integrations_castle_webhooks

    serialize :body
  end
end
