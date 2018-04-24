# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  layout 'devise'

  def twitter
    user = User.find_or_create_for_oauth request.env['omniauth.auth']

    if user.persisted?
      sign_in_and_redirect user, event: :authentication
      set_flash_message(:notice, :success, kind: 'Twitter') if is_navigational_format?
    else
      flash[:error] = t('.error')
      redirect_to new_user_registration_url
    end
  end
end
