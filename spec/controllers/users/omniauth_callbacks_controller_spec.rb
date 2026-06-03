# frozen_string_literal: true

RSpec.describe Users::OmniauthCallbacksController do
  before { request.env['devise.mapping'] = Devise.mappings[:user] }

  let(:user_id) { rand(100) }

  describe '#twitter' do
    let(:user) { create(:user, id: user_id) }

    before do
      allow(User).to receive(:find_or_create_for_oauth).and_return(user)
    end

    context 'when user is valid and persisted' do
      let(:risk_args) do
        {
          type: '$login',
          status: '$succeeded',
          request_token: nil,
          user: { id: user.id, email: user.email }
        }
      end

      before do
        allow(controller.castle).to receive(:risk).and_return(verdict)
        get :twitter
      end

      context 'when user allowed' do
        let(:verdict) { { policy: { action: 'allow' } } }

        it { expect(response).to redirect_to root_path }
        it { expect(controller.castle).to have_received(:risk).with(risk_args) }
      end

      context 'when user challenged' do
        let(:verdict) { { policy: { action: 'challenge' } } }

        it { expect(response).to redirect_to root_path }
        it { expect(controller.castle).to have_received(:risk).with(risk_args) }
      end

      context 'when user denied' do
        let(:verdict) { { policy: { action: 'deny' } } }
        let(:error_message) { I18n.t('users.omniauth_callbacks.twitter.access_denied') }

        it { expect(response).to redirect_to new_user_session_path }
        it { expect(flash['error']).to eq error_message }
        it { expect(controller.castle).to have_received(:risk).with(risk_args) }
      end
    end

    context 'when user is not valid and not persisted' do
      let(:user) { build(:user, id: user_id) }
      let(:filter_args) do
        { type: '$login', status: '$failed', request_token: nil, user: { id: user_id } }
      end

      before do
        allow(controller.castle).to receive(:filter)
        get :twitter
      end

      it { expect(response).to redirect_to new_user_registration_path }
      it { expect(controller.castle).to have_received(:filter).with(filter_args) }
    end
  end
end
