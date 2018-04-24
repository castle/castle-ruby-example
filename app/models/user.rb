# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: %i[twitter]

  def self.find_or_create_for_oauth(auth)
    find_or_initialize_by(
      provider: auth.provider,
      uid: auth.uid
    ).tap do |user|
      user.password = Devise.friendly_token[0,20]
      user.email = auth.info.email
      user.save
    end
  end
end
