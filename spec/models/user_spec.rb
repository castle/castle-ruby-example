# frozen_string_literal: true

RSpec.describe User do
  describe '.find_or_create_for_oauth' do
    let(:email) { Faker::Internet.email }
    let(:auth) do
      OmniAuth::AuthHash.new(provider: 'twitter', uid: '12345', info: { email: email })
    end

    context 'when no matching user exists' do
      it 'creates a new user' do
        expect { described_class.find_or_create_for_oauth(auth) }
          .to change(described_class, :count).by(1)
      end

      it 'persists the provider, uid and email' do
        user = described_class.find_or_create_for_oauth(auth)

        expect(user).to have_attributes(
          provider: 'twitter',
          uid: '12345',
          email: email,
          persisted?: true
        )
      end
    end

    context 'when a user with the same provider and uid exists' do
      let!(:existing) do
        create(:user, provider: 'twitter', uid: '12345', email: Faker::Internet.email)
      end

      it 'does not create another user' do
        expect { described_class.find_or_create_for_oauth(auth) }
          .not_to change(described_class, :count)
      end

      it 'returns the existing record' do
        expect(described_class.find_or_create_for_oauth(auth).id).to eq existing.id
      end
    end
  end
end
