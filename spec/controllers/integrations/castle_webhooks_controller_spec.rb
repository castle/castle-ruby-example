# frozen_string_literal: true

RSpec.describe Integrations::CastleWebhooksController do
  describe 'GET #index' do
    before { get :index }

    it { expect(response).to render_template(:index) }
    it { expect(response).to have_http_status(:ok) }
  end

  describe 'POST #create' do
    subject(:create_request) { post :create, body: raw_body }

    let(:raw_body) { {}.to_json }
    let(:headers) { { 'Content-Type' => 'application/json' } }

    before { request.headers.merge! headers }

    context 'when request was not sent by the Castle backend' do
      it { expect { create_request }.to raise_error(ActionController::RoutingError) }
    end

    context 'when the signature is present but does not match' do
      let(:headers) do
        { 'X-Castle-Signature' => 'definitely-not-a-valid-signature', 'Content-Type' => 'application/json' }
      end

      before { allow(Castle.config).to receive(:api_secret).and_return('some-secret') }

      it { expect { create_request }.to raise_error(ActionController::RoutingError) }
    end

    context 'when request was send by the Castle backend' do
      let(:castle_secret) { 'V9Q86iQBWi4xAbleSMrk4+cYhoUMIiiHvIwMl9jh9uo=' }
      let(:headers) do
        {
          'X-Castle-Signature' => 'c5rwq+SNCY8oyeOVKdvscmNIzMOmTb9U6VB/Iv6A+ys=',
          'Content-Type' => 'application/json'
        }
      end
      let(:raw_body) do
        {
          'api_version': 'v1',
          'app_id': '12345678901234',
          'type': '$review.opened'
        }.to_json
      end

      before do
        allow(Castle.config).to receive(:api_secret).and_return(castle_secret)
      end

      it 'expect to create a webhook in the local db' do
        expect { create_request }.to change(Integrations::CastleWebhook, :count).by(1)
      end

      context 'when request has happened' do
        before { create_request }

        it { expect(response).to have_http_status(:no_content) }
      end
    end
  end
end
