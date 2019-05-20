# frozen_string_literal: true

RSpec.describe Users::OmniauthCallbacksController do
  before { request.env['devise.mapping'] = Devise.mappings[:user] }

  let(:user_id) { rand(100) }

  describe '#twitter' do
    let(:user) { create(:user, id: user_id) }
    let(:user_attributes) { user.attributes }

    before do
      user_attributes
      allow(User).to receive(:find_or_create_for_oauth).and_return(user)
    end

    context 'when user is valid and persisted' do
      let(:castle_auth_args) do
        {
          event: '$login.succeeded',
          user_id: user.id,
          user_traits: user_attributes
        }
      end

      before do
        allow(controller.castle).to receive(:authenticate).and_return(verdict)
        get :twitter
      end

      context 'when user allowed' do
        let(:verdict) { { action: 'allow' } }

        it { expect(response).to redirect_to root_path }
        it { expect(controller.castle).to have_received(:authenticate).with(castle_auth_args) }
      end

      context 'when user challenged' do
        let(:verdict) { { action: 'challenge' } }

        it { expect(response).to redirect_to root_path }
        it { expect(controller.castle).to have_received(:authenticate).with(castle_auth_args) }
      end

      context 'when user denied' do
        let(:verdict) { { action: 'deny' } }
        let(:error_message) { I18n.t('users.omniauth_callbacks.twitter.access_denied') }

        it { expect(response).to redirect_to new_user_session_path }
        it { expect(flash['error']).to eq error_message }
        it { expect(controller.castle).to have_received(:authenticate).with(castle_auth_args) }
      end
    end

    context 'when user is not valid and not persisted' do
      let(:user) { build(:user, id: user_id) }
      let(:castle_track_args) { { event: '$login.failed', user_id: user_id } }

      before do
        allow(controller.castle).to receive(:track)
        get :twitter
      end

      it { expect(response).to redirect_to new_user_registration_path }
      it { expect(controller.castle).to have_received(:track).with(castle_track_args) }
    end
  end
end
