# frozen_string_literal: true

RSpec.describe Users::ProfilesController do
  describe 'GET #edit' do
    subject { get :edit }

    context 'for unauthenticated request' do
      it 'redirects to a sign in path' do
        expect(subject).to redirect_to new_user_session_path
      end
    end

    context 'for authenticated user' do
      with_user

      it 'renders the edit template' do
        expect(response).to have_http_status(:ok)
        expect(subject).to render_template(:edit)
      end

      it 'does not trigger castle tracking for page view' do
        expect_any_instance_of(Castle::Client).not_to receive(:track)
        subject
      end
    end
  end

  describe 'POST #update' do
    pending
  end
end
