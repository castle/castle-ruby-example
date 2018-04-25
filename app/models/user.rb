# frozen_string_literal: true

# User representation
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: %i[twitter]

  # Finds or creates a user based on the provided OAuth auth data
  # @param [OmniAuth::AuthHash]
  # @return [User]
  def self.find_or_create_for_oauth(auth)
    find_or_initialize_by(
      provider: auth.provider,
      uid: auth.uid
    ).tap do |user|
      user.password = Devise.friendly_token[0, 20]
      user.email = auth.info.email
      user.save
    end
  end
end
