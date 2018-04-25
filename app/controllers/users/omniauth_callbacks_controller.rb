# frozen_string_literal: true

module Users
  # OmniAuth authentication for Devise with Castle.io tracking
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    layout 'devise'

    # Twitter OAuth endpoint
    def twitter
      current_user = User.find_or_create_for_oauth request.env['omniauth.auth']

      if current_user.persisted?
        verdict = castle.authenticate(
          event: '$login.succeeded',
          user_id: current_user.id,
          user_traits: current_user.attributes
        ).freeze

        case verdict[:action]
        when 'allow'
          sign_in_with_notice(current_user)
        when 'challenge'
          sign_in_with_notice(current_user)
        when 'deny'
          warden.logout
          flash[:error] = t('.access_denied')
          redirect_to new_user_session_url
        end
      else
        flash[:error] = t('.error')
        redirect_to new_user_registration_url
        castle.track(event: '$login.failed', user_id: current_user&.id)
      end
    end

    private

    def sign_in_with_notice(current_user)
      sign_in_and_redirect current_user, event: :authentication
      set_flash_message(:notice, :success, kind: 'Twitter') if is_navigational_format?
    end
  end
end
