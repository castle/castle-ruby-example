# frozen_string_literal: true

# Namespace for all the things related to working with users
module Users
  # OmniAuth authentication for Devise with Castle.io tracking
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    layout 'devise'

    # Twitter OAuth endpoint
    def twitter
      current_user = User.find_or_create_for_oauth request.env['omniauth.auth']

      if current_user.persisted?
        authenticate(current_user)
      else
        flash[:error] = t('.error')
        redirect_to new_user_registration_url
        report_failed_login(current_user)
      end
    end

    private

    # Checks if user can be authenticated and if so user will be signed in.
    # @param current_user [User] user that we want to authenticate
    def authenticate(current_user)
      if evaluate_login(current_user) == 'deny'
        warden.logout
        flash[:error] = t('.access_denied')
        redirect_to new_user_session_url
      else
        sign_in_with_notice(current_user)
      end
    end

    # Signs in user with a nice flash message (if applicable)
    # @param current_user [User] user that we want to sign in
    def sign_in_with_notice(current_user)
      sign_in_and_redirect current_user, event: :authentication
      set_flash_message(:notice, :success, kind: 'Twitter') if is_navigational_format?
    end

    # Sends a successful OAuth login to the risk endpoint and returns the verdict.
    # @param user [User]
    # @return [String] the Castle policy action: 'allow', 'challenge' or 'deny'
    def evaluate_login(user)
      castle.risk(
        type: '$login',
        status: '$succeeded',
        request_token: castle_request_token,
        user: { id: user.id, email: user.email }
      ).dig(:policy, :action)
    rescue Castle::Error
      'allow'
    end

    # Reports a failed OAuth login to the filter endpoint.
    # @param user [User]
    def report_failed_login(user)
      castle.filter(
        type: '$login',
        status: '$failed',
        request_token: castle_request_token,
        user: { id: user&.id }
      )
    rescue Castle::Error
      nil
    end
  end
end
