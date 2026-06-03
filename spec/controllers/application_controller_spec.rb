# frozen_string_literal: true

RSpec.describe ApplicationController do
  controller do
    def index
      render plain: 'authenticated'
    end
  end

  before { request.env['devise.mapping'] = Devise.mappings[:user] }

  describe 'authentication' do
    context 'when not signed in' do
      before { get :index }

      it { expect(response).to redirect_to new_user_session_path }
    end

    context 'when signed in' do
      with_user

      before { get :index }

      it { expect(response).to have_http_status(:ok) }
      it { expect(response.body).to eq 'authenticated' }
    end
  end

  describe '#castle_request_token' do
    it 'returns the submitted request token param' do
      controller.params[:castle_request_token] = 'tok_123'

      expect(controller.send(:castle_request_token)).to eq 'tok_123'
    end
  end
end
