# frozen_string_literal: true

RSpec.describe Users::PrivacyController do
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

    context 'when requesting user data' do
      with_user

      before do
        allow(controller.castle).to receive(:request_user_data).and_return(status: 'pending')
        post :create, params: { identifier: 'jane@example.com', identifier_type: '$email' }
      end

      it { expect(response).to render_template(:show) }

      it 'calls the request-user-data endpoint' do
        expect(controller.castle).to have_received(:request_user_data).with(
          identifier: 'jane@example.com', identifier_type: '$email'
        )
      end
    end

    context 'when deleting user data' do
      with_user

      before do
        allow(controller.castle).to receive(:delete_user_data).and_return(status: 'pending')
        post :create, params: { identifier: 'jane@example.com', identifier_type: '$email', commit_action: 'delete' }
      end

      it 'calls the delete-user-data endpoint' do
        expect(controller.castle).to have_received(:delete_user_data).with(
          identifier: 'jane@example.com', identifier_type: '$email'
        )
      end
    end

    context 'when Castle raises' do
      with_user

      before do
        allow(controller.castle).to receive(:request_user_data).and_raise(Castle::Error)
        post :create
      end

      it 'still renders without surfacing the error' do
        expect(response).to render_template(:show)
      end
    end
  end
end
