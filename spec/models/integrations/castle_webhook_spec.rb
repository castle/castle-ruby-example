# frozen_string_literal: true

RSpec.describe Integrations::CastleWebhook do
  context 'when we create a new webhook' do
    let(:body) { { rand.to_s => rand } }
    let(:webhook) { described_class.create!(body: body) }

    it 'expect to store json body' do
      expect(webhook.body).to eq body
    end
  end
end
