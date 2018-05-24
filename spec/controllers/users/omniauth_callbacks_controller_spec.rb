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

        it 'expect to sign in and redirect to root' do
          expect(response).to redirect_to root_path
        end

        it 'expect to run castle authentication' do
          expect(controller.castle)
            .to have_received(:authenticate)
            .with(castle_auth_args)
        end
      end

      context 'when user challenged' do
        let(:verdict) { { action: 'challenge' } }

        it 'expect to sign in and redirect to root' do
          expect(response).to redirect_to root_path
        end

        it 'expect to run castle authentication' do
          expect(controller.castle)
            .to have_received(:authenticate)
            .with(castle_auth_args)
        end
      end

      context 'when user denied' do
        let(:verdict) { { action: 'deny' } }

        it 'expect to redirect to sign in path with a proper message' do
          expect(response).to redirect_to new_user_session_path
          expect(flash['error']).to eq I18n.t('users.omniauth_callbacks.twitter.access_denied')
        end

        it 'expect to run castle authentication' do
          expect(controller.castle)
            .to have_received(:authenticate)
            .with(castle_auth_args)
        end
      end
    end

    context 'when user is not valid and not persisted' do
      let(:user) { build(:user, id: user_id) }

      before do
        allow(controller.castle).to receive(:track)
        get :twitter
      end

      it { expect(response).to redirect_to new_user_registration_path }
      it 'expect to track failed login with castle api' do
        expect(controller.castle)
          .to have_received(:track)
          .with(event: '$login.failed', user_id: user_id)
      end
    end
  end
end
