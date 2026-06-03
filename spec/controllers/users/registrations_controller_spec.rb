# frozen_string_literal: true

RSpec.describe Users::RegistrationsController do
  before { request.env['devise.mapping'] = Devise.mappings[:user] }

  describe 'GET #new' do
    before { get :new }

    it { expect(response).to have_http_status(:ok) }
    it { expect(response).to render_template(:new) }
  end

  describe 'POST #create' do
    let(:password) { 'sup3r-s3cret' }
    let(:params) do
      { user: { email: Faker::Internet.email, password: password, password_confirmation: password } }
    end

    it 'creates a new user' do
      expect { post :create, params: params }.to change(User, :count).by(1)
    end

    it 'signs the user in' do
      post :create, params: params

      expect(controller.current_user).to be_present
      expect(response).to redirect_to root_path
    end
  end
end
