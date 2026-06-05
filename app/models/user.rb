# frozen_string_literal: true

# User representation
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :rememberable, :trackable, :validatable
end
