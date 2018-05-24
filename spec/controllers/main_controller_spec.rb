# frozen_string_literal: true

RSpec.describe MainController do
  describe 'GET #index' do
    subject(:main_page) { get :index }

    context 'when unauthenticated user fetches the main page' do
      it 'renders the index template' do
        expect(response).to have_http_status(:ok)
        expect(main_page).to render_template(:index)
      end
    end

    context 'when authenticated user fetches the main page' do
      with_user

      it 'renders the index template' do
        expect(response).to have_http_status(:ok)
        expect(main_page).to render_template(:index)
      end
    end
  end
end
