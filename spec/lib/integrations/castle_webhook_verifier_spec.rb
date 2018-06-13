# frozen_string_literal: true

RSpec.describe Integrations::CastleWebhookVerifier do
  subject(:result) { described_class.valid?(incoming_data, incoming_signature) }

  let(:incoming_data) { rand.to_s }

  context 'when incoming_signature is empty' do
    let(:incoming_signature) { '' }

    it { is_expected.to be false }
  end

  context 'when incoming signature does not match data' do
    let(:incoming_signature) { 'thNnmggU2ex3L5XXeMNfxf8Wl8STcVZTxscSFEKSxa0=' }

    it { is_expected.to be false }
  end

  context 'when incoming_signature matches the data' do
    let(:castle_secret) { 'V9Q86iQBWi4xAbleSMrk4+cYhoUMIiiHvIwMl9jh9uo=' }
    let(:incoming_signature) { 'c5rwq+SNCY8oyeOVKdvscmNIzMOmTb9U6VB/Iv6A+ys=' }
    let(:incoming_data) do
      {
        'api_version': 'v1',
        'app_id': '12345678901234',
        'type': '$review.opened'
      }.to_json
    end

    # We need to stub the castle secret for this particular case, because we cannot rely on
    # a user one for hardcoded signature example as the valid signature was precalculated
    before do
      allow(Rails.application.secrets)
        .to receive(:castle_secret)
        .and_return(castle_secret)
    end

    it { is_expected.to be true }
  end
end
