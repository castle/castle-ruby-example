Rails.application.routes.draw do
  devise_controllers = {}

  %i[
    sessions
    confirmations
    passwords
    registrations
    unlocks
  ].each do |action|
    devise_controllers[action] = "users/#{action}"
  end

  devise_for :users, controllers: devise_controllers

  root to: 'main#index'
end
