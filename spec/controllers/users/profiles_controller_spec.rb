# frozen_string_literal: true

RSpec.describe Users::ProfilesController do
  describe 'GET #edit' do
    context 'when unauthenticated user wants to edit his profile' do
      before { get :edit }

      it { expect(response).to redirect_to new_user_session_path }
    end

    context 'when authenticated user wants to edit his profile' do
      with_user

      before do
        allow(controller.castle).to receive(:track)
        get :edit
      end

      it { expect(response).to render_template(:edit) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(controller.castle).not_to have_received(:track) }
    end
  end

  describe 'POST #update' do
    let(:params) { {} }

    context 'when unauthenticated user wants to update his profile' do
      before { put :update, params: params }

      it { expect(response).to redirect_to new_user_session_path }
    end

    context 'when authenticated user wants to update his profile' do
      with_user

      context 'with invalid data' do
        let(:params) { { user: { email: '' } } }
        let(:track_expected_data) do
          {
            event: '$profile_update.failed',
            user_id: controller.current_user.id,
            user_traits: controller.current_user.attributes
          }
        end

        before do
          allow(controller.castle).to receive(:track)
          put :update, params: params
        end

        it { expect(response).to render_template(:edit) }
        it { expect(response).to have_http_status(:ok) }
        it { expect(controller.castle).to have_received(:track).with(track_expected_data) }
      end

      context 'with valid data' do
        let(:params) { { user: { email: Faker::Internet.email } } }
        let(:track_expected_data) do
          {
            event: '$profile_update.succeeded',
            user_id: controller.current_user.id,
            user_traits: controller.current_user.attributes
          }
        end

        before do
          allow(controller.castle).to receive(:track)
          put :update, params: params
        end

        it { expect(response).to redirect_to root_path }
        it { expect(controller.castle).to have_received(:track).with(track_expected_data) }
      end
    end
  end
end
