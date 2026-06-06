# frozen_string_literal: true

RSpec.describe Users::PasswordResetsController do
  render_views

  describe 'GET #show' do
    context 'when unauthenticated' do
      before { get :show }

      it { expect(response).to redirect_to new_user_session_path }
    end

    context 'when authenticated' do
      with_user

      before { get :show }

      it { expect(response).to render_template(:show) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe 'POST #create' do
    context 'when unauthenticated' do
      before { post :create }

      it { expect(response).to redirect_to new_user_session_path }
    end

    context 'when a new password is supplied' do
      with_user

      before do
        allow(controller.castle).to receive(:log)
        post :create, params: { password: 'a-brand-new-password' }
      end

      it { expect(response).to render_template(:show) }

      it 'logs $password_reset / $succeeded' do
        expect(controller.castle).to have_received(:log).with(
          type: '$password_reset',
          status: '$succeeded',
          request_token: nil,
          user: { id: user.id, email: user.email }
        )
      end
    end

    context 'when the current password is reused' do
      let(:user) { create(:user, password: 'current-password-1') }

      before do
        @request.env['devise.mapping'] = Devise.mappings[:user]
        sign_in user
        allow(controller.castle).to receive(:log)
        post :create, params: { password: 'current-password-1' }
      end

      it 'logs $password_reset / $failed' do
        expect(controller.castle).to have_received(:log).with(hash_including(status: '$failed'))
      end
    end

    context 'when Castle raises' do
      with_user

      before do
        allow(controller.castle).to receive(:log).and_raise(Castle::Error)
        post :create, params: { password: 'a-brand-new-password' }
      end

      it 'still renders without surfacing the error' do
        expect(response).to render_template(:show)
      end
    end
  end
end
