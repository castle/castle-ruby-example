# frozen_string_literal: true

module Integrations
  # Local webhook representation for searching and working with webhooks that were received
  class CastleWebhook < ApplicationRecord
    self.table_name = :integrations_castle_webhooks

    serialize :body

    scope :recent, -> { order(created_at: :desc).limit(50) }
  end
end
