# frozen_string_literal: true

module Users
  # Sessions Devise management with integrated Castle.io Ruby library
  class SessionsController < Devise::SessionsController
    layout 'devise'

    # Key that is used in Devise for user authentication
    AUTHENTICATION_KEY = 'email'

    # Sign in with Castle. The attempt is filtered first while the visitor is
    # still anonymous; a successful login is then risk-assessed, reusing the
    # same request token. Each call is recorded so the next page can show the
    # payload sent to Castle and the verdict that came back.
    # @note A 'challenge' verdict is treated as 'allow' here; a real app would
    #   step up to MFA. 'deny' blocks the login.
    def create
      return deny_login if castle_action(filter_login_attempt) == 'deny'

      if warden.authenticate(auth_options)
        if castle_action(evaluate_login(current_user)) == 'deny'
          warden.logout
          deny_login
        else
          persist_castle_results
          super
        end
      else
        track_failed_login
        persist_castle_results
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
      log_logout(user_id, token)
      persist_castle_results
    end

    private

    # The submitted login email (anonymous form data, before authentication).
    def login_email
      params.dig(:user, AUTHENTICATION_KEY)
    end

    # Denies the login: surface the reason, keep the recorded Castle calls and
    # bounce back to the sign-in form.
    def deny_login
      flash[:error] = t('.access_denied')
      persist_castle_results
      redirect_to new_user_session_url
    end

    # Filters the login attempt while the visitor is still anonymous, before the
    # credentials are checked (so the email goes in params).
    # @return [Hash, nil] the Castle response, or nil when the call raised
    def filter_login_attempt
      payload = {
        type: '$login',
        status: '$attempted',
        request_token: castle_request_token,
        params: { email: login_email }
      }
      result = castle.filter(**payload)
      record_castle_result(endpoint: 'filter', payload: payload, response: result)
      result
    rescue Castle::Error => e
      record_castle_result(endpoint: 'filter', payload: payload, error: e)
      nil
    end

    # Reports a failed login to the filter endpoint, resolving any existing user
    # via matching_user_id.
    def track_failed_login
      email = login_email
      user = User.find_by(AUTHENTICATION_KEY => email)

      payload = {
        type: '$login',
        status: '$failed',
        request_token: castle_request_token,
        params: { email: email }
      }
      payload[:matching_user_id] = user.id.to_s if user

      result = castle.filter(**payload)
      record_castle_result(endpoint: 'filter', payload: payload, response: result)
    rescue Castle::Error => e
      record_castle_result(endpoint: 'filter', payload: payload, error: e)
    end

    # Sends a successful login to the risk endpoint and returns the verdict.
    # @param user [User]
    # @return [Hash, nil] the Castle response, or nil when the call raised
    def evaluate_login(user)
      payload = {
        type: '$login',
        status: '$succeeded',
        request_token: castle_request_token,
        user: { id: user.id.to_s, email: user.email }
      }
      result = castle.risk(**payload)
      record_castle_result(endpoint: 'risk', payload: payload, response: result)
      result
    rescue Castle::Error => e
      # Never lock a user out because Castle is unhappy with the request.
      record_castle_result(endpoint: 'risk', payload: payload, error: e)
      nil
    end

    # Records the logout with the non-blocking log endpoint.
    def log_logout(user_id, token)
      payload = {
        type: '$logout',
        status: '$succeeded',
        request_token: token,
        user: { id: user_id&.to_s }
      }
      result = castle.log(**payload)
      record_castle_result(endpoint: 'log', payload: payload, response: result)
    rescue Castle::Error => e
      record_castle_result(endpoint: 'log', payload: payload, error: e)
    end
  end
end
