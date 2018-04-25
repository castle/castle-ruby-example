# frozen_string_literal: true

# Root page controller
class MainController < ApplicationController
  skip_before_action :authenticate_user!
end
