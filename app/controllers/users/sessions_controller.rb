# frozen_string_literal: true

module Users
  # Sessions Devise management with integrated Castle.io Ruby library
  class SessionsController < Devise::SessionsController
    layout 'devise'

    # Key that is used in Devise for user authentication
    AUTHENTICATION_KEY = 'email'

    # Sign in with Castle tracking.
    # @note For now we allow user when verdict is not deny. Challenge could be implemented
    def create
      if warden.authenticate(auth_options)
        case authenticate_with_castle(current_user)[:action]
        when 'allow'
          super
        when 'challenge'
          super
        when 'deny'
          warden.logout
          flash[:error] = t('.access_denied')
          redirect_to new_user_session_url
        end
      else
        user_details = request.filtered_parameters.fetch('user') { {} }
        user = User.find_by(AUTHENTICATION_KEY => user_details[AUTHENTICATION_KEY])
        castle.track(event: '$login.failed', user_id: user&.id, user_traits: user_details)
        throw(:warden)
      end
    end

    # Sign out with Castle tracking
    def destroy
      # This is a failover just in case there is no user because an unauthenticated user
      # tried to logout
      user_id = current_user&.id
      super
      castle.track(event: '$logout.succeeded', user_id: user_id)
    end

    private

    # Authenticates user in Castle
    # @param current_user [User]
    # @return [Hash] verdict details
    def authenticate_with_castle(current_user)
      castle.authenticate(
        event: '$login.succeeded',
        user_id: current_user.id,
        user_traits: current_user.attributes
      ).freeze
    end
  end
end
