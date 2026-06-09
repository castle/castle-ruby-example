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
    let(:email) { Faker::Internet.email }
    let(:params) do
      { user: { email: email, password: password, password_confirmation: password } }
    end

    context 'when the registration is allowed' do
      before { allow(controller.castle).to receive(:filter).and_return(policy: { action: 'allow' }) }

      it 'creates a new user' do
        expect { post :create, params: params }.to change(User, :count).by(1)
      end

      it 'signs the user in' do
        post :create, params: params

        expect(controller.current_user).to be_present
        expect(response).to redirect_to root_path
      end

      it 'filters the registration attempt before creating the account' do
        post :create, params: params

        expect(controller.castle).to have_received(:filter).with(
          type: '$registration',
          status: '$attempted',
          request_token: nil,
          params: { email: email }
        )
      end
    end

    context 'when the registration is denied' do
      before { allow(controller.castle).to receive(:filter).and_return(policy: { action: 'deny' }) }

      it 'does not create the account' do
        expect { post :create, params: params }.not_to change(User, :count)
      end

      it 'redirects back to the sign-up form' do
        post :create, params: params

        expect(response).to redirect_to new_user_registration_url
      end
    end

    context 'when Castle raises while filtering the attempt' do
      before { allow(controller.castle).to receive(:filter).and_raise(Castle::Error) }

      it 'fails open and keeps the user' do
        expect { post :create, params: params }.to change(User, :count).by(1)
        expect(response).to redirect_to root_path
      end
    end

    context 'when the registration is invalid' do
      let(:params) { { user: { email: '', password: password, password_confirmation: password } } }

      before { allow(controller.castle).to receive(:filter) }

      it 're-renders the form and reports a failed registration' do
        expect { post :create, params: params }.not_to change(User, :count)

        expect(response).to render_template(:new)
        expect(controller.castle).to have_received(:filter).with(
          hash_including(type: '$registration', status: '$failed')
        )
      end
    end
  end
end
