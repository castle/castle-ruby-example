# frozen_string_literal: true

RSpec.describe MainController do
  describe 'GET #index' do
    context 'when unauthenticated user fetches the main page' do
      before { get :index }

      it { expect(response).to have_http_status(:ok) }
      it { expect(response).to render_template(:index) }
    end

    context 'when authenticated user fetches the main page' do
      with_user

      before { get :index }

      it { expect(response).to have_http_status(:ok) }
      it { expect(response).to render_template(:index) }
    end
  end
end
