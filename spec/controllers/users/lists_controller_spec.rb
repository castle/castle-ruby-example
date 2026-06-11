# frozen_string_literal: true

RSpec.describe Users::ListsController do
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

    context 'when authenticated' do
      with_user

      before do
        allow(controller.castle).to receive(:create_list).and_return(id: 'list_1')
        allow(controller.castle).to receive(:get_all_lists).and_return([])
        post :create, params: { name: 'demo-blocklist', color: '$red', primary_field: 'user.email' }
      end

      it { expect(response).to render_template(:show) }

      it 'creates a list and fetches all lists' do
        expect(controller.castle).to have_received(:create_list).with(
          name: 'demo-blocklist', color: '$red', primary_field: 'user.email'
        )
        expect(controller.castle).to have_received(:get_all_lists)
      end

      it 'renders the Castle activity panel with the call result' do
        expect(response.body).to include('Castle activity')
        expect(response.body).to include('/lists')
        expect(response.body).to include('Response from Castle')
      end
    end

    context 'when Castle raises' do
      with_user

      before do
        allow(controller.castle).to receive(:create_list).and_raise(Castle::Error)
        post :create
      end

      it 'still renders without surfacing the error' do
        expect(response).to render_template(:show)
      end
    end
  end
end
