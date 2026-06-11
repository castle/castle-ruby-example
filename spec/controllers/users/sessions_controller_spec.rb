# frozen_string_literal: true

RSpec.describe Users::SessionsController do
  before { request.env['devise.mapping'] = Devise.mappings[:user] }

  describe 'GET new' do
    before do
      allow(controller.castle).to receive(:risk)
      get :new
    end

    it { expect(response.status).to eq 200 }
    it { expect(response).to render_template 'new' }
    it { expect(controller.castle).not_to have_received(:risk) }
  end

  describe 'POST create' do
    let(:password) { rand.to_s }
    let(:user) { create(:user, password: password, password_confirmation: password) }

    # @note We cannot directly check the castle invocation because of the way warden works
    # and how it redirects
    context 'when login failed' do
      before do
        # Since the expectations are handled after the redirect for invalid, we don't have a way
        # to reference the "future" castle object, so we have to stub all the instances
        allow_any_instance_of(controller.castle.class)
          .to receive(:filter).and_return(policy: { action: 'allow' })
        post :create, params: { user: { email: user.email, password: rand.to_s } }
      end

      it { expect(response).to redirect_to new_user_session_path }
    end

    context 'when login failed and Castle raises an error' do
      before do
        allow_any_instance_of(controller.castle.class).to receive(:filter).and_raise(Castle::Error)
        post :create, params: { user: { email: user.email, password: rand.to_s } }
      end

      it 'still redirects without surfacing the error' do
        expect(response).to redirect_to new_user_session_path
      end
    end

    context 'when the attempt is filtered out' do
      before do
        allow(controller.castle).to receive(:filter).and_return(policy: { action: 'deny' })
        allow(controller.castle).to receive(:risk)
        post :create, params: { user: { email: user.email, password: password } }
      end

      it { expect(response).to redirect_to new_user_session_path }
      it { expect(flash['error']).to eq I18n.t('users.sessions.create.access_denied') }
      it { expect(controller.castle).not_to have_received(:risk) }

      it 'records the filter verdict for the results panel' do
        expect(flash[:castle_results].to_a.first).to include('endpoint' => 'filter')
      end
    end

    context 'when login succeeded' do
      let(:filter_args) do
        {
          type: '$login',
          status: '$attempted',
          request_token: nil,
          params: { email: user.email }
        }
      end
      let(:risk_args) do
        {
          type: '$login',
          status: '$succeeded',
          request_token: nil,
          user: { id: user.id.to_s, email: user.email }
        }
      end

      before do
        allow(controller.castle).to receive(:filter).and_return(policy: { action: 'allow' })
        allow(controller.castle).to receive(:risk).and_return(verdict)
        post :create, params: { user: { email: user.email, password: password } }
      end

      context 'when user allowed' do
        let(:verdict) { { policy: { action: 'allow' } } }

        it { expect(response).to redirect_to root_path }
        it { expect(controller.castle).to have_received(:filter).with(filter_args) }
        it { expect(controller.castle).to have_received(:risk).with(risk_args) }

        it 'records the filter then risk calls for the results panel' do
          endpoints = flash[:castle_results].to_a.map { |entry| entry['endpoint'] }
          expect(endpoints).to eq(%w[filter risk])
        end

        it 'records the risk response for display' do
          expect(flash[:castle_results].to_a.last['response']).to include('policy' => { 'action' => 'allow' })
        end
      end

      context 'when user challenged' do
        let(:verdict) { { policy: { action: 'challenge' } } }

        it { expect(response).to redirect_to root_path }
        it { expect(controller.castle).to have_received(:risk).with(risk_args) }
      end

      context 'when user denied' do
        let(:verdict) { { policy: { action: 'deny' } } }
        let(:error_message) { I18n.t('users.sessions.create.access_denied') }

        it { expect(response).to redirect_to new_user_session_path }
        it { expect(flash['error']).to eq error_message }
        it { expect(controller.castle).to have_received(:risk).with(risk_args) }

        it 'records the denied risk verdict for the results panel' do
          expect(flash[:castle_results].to_a.last['response']).to include('policy' => { 'action' => 'deny' })
        end
      end
    end

    context 'when Castle raises during risk assessment' do
      before do
        allow(controller.castle).to receive(:filter).and_return(policy: { action: 'allow' })
        allow(controller.castle).to receive(:risk).and_raise(Castle::Error)
        post :create, params: { user: { email: user.email, password: password } }
      end

      it 'fails open and allows the login' do
        expect(response).to redirect_to root_path
      end
    end
  end

  describe 'DELETE destroy' do
    with_user

    let(:log_args) { { type: '$logout', status: '$succeeded', request_token: nil, user: { id: user.id.to_s } } }

    before do
      allow(controller.castle).to receive(:log)
      delete :destroy
    end

    it { expect(flash[:notice]).to eq I18n.t('devise.sessions.signed_out') }
    it { expect(response).to redirect_to root_path }
    it { expect(controller.castle).to have_received(:log).with(log_args) }

    it 'records the logout for the results panel' do
      expect(flash[:castle_results].to_a.first).to include('endpoint' => 'log')
    end
  end
end
