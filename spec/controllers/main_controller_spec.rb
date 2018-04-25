# frozen_string_literal: true

RSpec.describe MainController do
  describe 'GET #index' do
    subject { get :index }

    context 'for unauthenticated request' do
      it 'renders the index template' do
        expect(response).to have_http_status(:ok)
        expect(subject).to render_template(:index)
      end
    end

    context 'for authenticated user' do
      with_user

      it 'renders the index template' do
        expect(response).to have_http_status(:ok)
        expect(subject).to render_template(:index)
      end
    end
  end
end
