# frozen_string_literal: true

RSpec.describe Users::ProfilesController do
  describe 'GET #edit' do
    subject(:edit_page) { get :edit }

    context 'when unauthenticated user wants to edit his profile' do
      it 'redirects to a sign in path' do
        expect(edit_page).to redirect_to new_user_session_path
      end
    end

    context 'when authenticated user wants to edit his profile' do
      with_user

      before { allow(controller.castle).to receive(:track) }

      it 'renders the edit template' do
        expect(edit_page).to render_template(:edit)
        expect(response).to have_http_status(:ok)
      end

      it 'does not trigger castle tracking for page view' do
        edit_page
        expect(controller.castle).not_to have_received(:track)
      end
    end
  end

  describe 'POST #update' do
    subject(:update_page) { put :update, params: params }

    let(:params) { {} }

    context 'when unauthenticated user wants to update his profile' do
      it { expect(update_page).to redirect_to new_user_session_path }
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
          update_page
        end

        it { expect(update_page).to render_template(:edit) }
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

        before { allow(controller.castle).to receive(:track) }

        it 'renders the edit template' do
          expect(response).to have_http_status(:ok)
          expect(update_page).to redirect_to root_path
        end

        it 'expect to trigger castle tracking for succeeded profile update' do
          update_page
          expect(controller.castle).to have_received(:track).with(track_expected_data)
        end
      end
    end
  end
end
