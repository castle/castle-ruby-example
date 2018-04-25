# frozen_string_literal: true

RSpec.describe Users::SessionsController do
  before { request.env['devise.mapping'] = Devise.mappings[:user] }

  describe 'GET new' do
    before do
      allow(controller.castle).to receive(:authenticate)
      get :new
    end

    it 'expects to return an OK (200) status code' do
      expect(response.status).to eq 200
    end

    it 'expects to render with new template' do
      expect(response).to render_template 'new'
    end

    it 'expects not to track anything' do
      expect(controller.castle).not_to have_received(:authenticate)
    end
  end

  describe 'POST create' do
    let(:password) { rand.to_s }
    let(:user) { create(:user, password: password, password_confirmation: password) }

    context 'when login failed' do
      pending
    end

    context 'when login succeeded' do
      let(:castle_auth_args) do
        {
          event: '$login.succeeded',
          user_id: user.id,
          user_traits: controller.current_user.attributes
        }
      end

      before do
        allow(controller.castle).to receive(:authenticate).and_return(verdict)
        post :create, params: { user: { email: user.email, password: password } }
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
  end

  describe 'DELETE destroy' do
    with_user

    before do
      allow(controller.castle).to receive(:track)
      delete :destroy
    end

    it 'expects to redirect to root path with a proper message' do
      expect(flash[:notice]).to eq I18n.t('devise.sessions.signed_out')
      expect(response).to redirect_to root_path
    end

    it 'expects to track with castle api' do
      expect(controller.castle)
        .to have_received(:track)
        .with(event: '$logout.succeeded', user_id: user.id)
    end
  end
end
