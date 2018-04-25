# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { Devise.friendly_token[0, 20] }
  end
end
