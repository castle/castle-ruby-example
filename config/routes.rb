# frozen_string_literal: true

Rails.application.routes.draw do
  devise_controllers = {}

  %i[
    sessions
    passwords
    registrations
  ].each do |action|
    devise_controllers[action] = "users/#{action}"
  end

  devise_for :users, controllers: devise_controllers

  namespace :users do
    resource :profile, only: %i[edit update]
    resource :custom_event, only: %i[create]
    resource :password_reset, only: %i[show create]
    resource :lists, only: %i[show create]
    resource :privacy, only: %i[show create], controller: 'privacy'
  end

  namespace :integrations do
    resources :castle_webhooks, only: %i[index create]
  end

  root to: 'main#index'
end
