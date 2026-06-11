# frozen_string_literal: true

RSpec.describe Users::CustomEventsController do
  describe 'POST #create' do
    context 'when unauthenticated' do
      before { post :create }

      it { expect(response).to redirect_to new_user_session_path }
    end

    context 'when authenticated' do
      with_user

      before do
        allow(controller.castle).to receive(:log)
        post :create
      end

      it { expect(response).to redirect_to edit_users_profile_path }

      it 'logs a custom event for the current user' do
        expect(controller.castle).to have_received(:log).with(
          type: '$custom',
          name: 'Demo custom event',
          status: '$succeeded',
          request_token: nil,
          user: { id: user.id.to_s, email: user.email }
        )
      end
    end

    context 'when Castle raises' do
      with_user

      before do
        allow(controller.castle).to receive(:log).and_raise(Castle::Error)
        post :create
      end

      it 'still redirects without surfacing the error' do
        expect(response).to redirect_to edit_users_profile_path
      end
    end
  end
end
