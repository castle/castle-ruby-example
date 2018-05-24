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
        expect(response).to have_http_status(:ok)
        expect(edit_page).to render_template(:edit)
      end

      it 'does not trigger castle tracking for page view' do
        edit_page
        expect(controller.castle).not_to have_received(:track)
      end
    end
  end

  describe 'POST #update' do
    pending
  end
end
