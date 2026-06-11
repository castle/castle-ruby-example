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
        allow(controller.castle).to receive(:log)
        get :edit
      end

      it { expect(response).to render_template(:edit) }
      it { expect(response).to have_http_status(:ok) }
      it { expect(controller.castle).not_to have_received(:log) }
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
        let(:log_expected_data) do
          {
            type: '$profile_update',
            status: '$failed',
            request_token: nil,
            user: { id: controller.current_user.id.to_s, email: controller.current_user.email }
          }
        end

        before do
          allow(controller.castle).to receive(:log)
          put :update, params: params
        end

        it { expect(response).to render_template(:edit) }
        it { expect(response).to have_http_status(:ok) }
        it { expect(controller.castle).to have_received(:log).with(log_expected_data) }
      end

      context 'with valid data' do
        let(:params) { { user: { email: Faker::Internet.email } } }
        let(:log_expected_data) do
          {
            type: '$profile_update',
            status: '$succeeded',
            request_token: nil,
            user: { id: controller.current_user.id.to_s, email: controller.current_user.email }
          }
        end

        before do
          allow(controller.castle).to receive(:log)
          put :update, params: params
        end

        it { expect(response).to redirect_to root_path }
        it { expect(controller.castle).to have_received(:log).with(log_expected_data) }

        it 'records the profile update for the results panel' do
          expect(flash[:castle_results].to_a.first).to include('endpoint' => 'log')
        end
      end

      context 'when Castle raises while logging' do
        let(:params) { { user: { email: Faker::Internet.email } } }

        before do
          allow(controller.castle).to receive(:log).and_raise(Castle::Error)
          put :update, params: params
        end

        it 'still completes the update without surfacing the error' do
          expect(response).to redirect_to root_path
        end
      end
    end
  end
end
