# frozen_string_literal: true

Rails.application.routes.draw do
  devise_controllers = {}

  %i[
    sessions
    passwords
    registrations
    omniauth_callbacks
  ].each do |action|
    devise_controllers[action] = "users/#{action}"
  end

  devise_for :users, controllers: devise_controllers

  namespace :users do
    resource :profile, only: %i[edit update]
  end

  namespace :integrations do
    resources :castle_webhooks, only: %i[create]
  end

  root to: 'main#index'
end
