# frozen_string_literal: true

module Users
  # Sessions Devise management with integrated Castle.io Ruby library
  class SessionsController < Devise::SessionsController
    layout 'devise'

    # Key that is used in Devise for user authentication
    AUTHENTICATION_KEY = 'email'

    # Sign in with Castle risk assessment.
    # @note A 'challenge' verdict is treated as 'allow' here; a real app would
    #   step up to MFA. 'deny' blocks the login.
    def create
      if warden.authenticate(auth_options)
        if evaluate_login(current_user) == 'deny'
          warden.logout
          flash[:error] = t('.access_denied')
          redirect_to new_user_session_url
        else
          super
        end
      else
        track_failed_login
        throw(:warden)
      end
    end

    # Sign out, logged to Castle with the non-blocking log endpoint.
    def destroy
      # This is a failover just in case there is no user because an unauthenticated user
      # tried to logout
      user_id = current_user&.id
      token = castle_request_token
      super
      castle.log(
        type: '$logout',
        status: '$succeeded',
        request_token: token,
        user: { id: user_id }
      )
    end

    private

    # Takes the request form data (login and password) and tries to find the user for which the
    # authentication process failed and reports a failed login to the filter endpoint.
    def track_failed_login
      user_params = params.fetch('user') { {} }.except(*Rails.application.config.filter_parameters)
      email = user_params[AUTHENTICATION_KEY]
      user = User.find_by(AUTHENTICATION_KEY => email)

      castle.filter(
        type: '$login',
        status: '$failed',
        request_token: castle_request_token,
        user: { id: user&.id, email: email },
        params: { email: email }
      )
    rescue Castle::Error
      nil
    end

    # Sends a successful login to the risk endpoint and returns the verdict.
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
      # Never lock a user out because Castle is unhappy with the request.
      'allow'
    end
  end
end
