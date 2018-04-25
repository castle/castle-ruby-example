# frozen_string_literal: true

RSpec.describe Users::OmniauthCallbacksController do
  before { @request.env['devise.mapping'] = Devise.mappings[:user] }

  let(:user_id) { rand(100) }
  let(:user_attributes) { { rand.to_s => rand } }
  let(:user) do
    instance_double(
      User,
      persisted?: persisted,
      id: user_id,
      attributes: user_attributes
    )
  end

  describe '#twitter' do
    before { expect(User).to receive(:find_or_create_for_oauth).and_return(user) }

    context 'when user is persisted' do
      pending
    end

    context 'when user is not persisted' do
      let(:persisted) { false }

      before do
        allow(controller.castle).to receive(:track)
        get :twitter, format: :html
      end

      it { expect(response).to redirect_to new_user_registration_path }
      it 'expect to track failed login with castle api' do
        expect(controller.castle)
          .to have_received(:track)
          .with(event: '$login.failed', user_id: user_id)
      end
    end
  end
end
