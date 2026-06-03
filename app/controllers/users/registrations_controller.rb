# frozen_string_literal: true

module Users
  # User registration Devise actions with integrated Castle.io risk assessment.
  class RegistrationsController < Devise::RegistrationsController
    layout 'devise'

    # Sign up with Castle risk assessment.
    # @note A 'challenge' verdict is treated as 'allow' here; a real app would
    #   step up to MFA. 'deny' rolls the registration back.
    def create
      build_resource(sign_up_params)

      if resource.save
        if evaluate_registration(resource) == 'deny'
          resource.destroy
          flash[:error] = t('.access_denied')
          redirect_to new_user_registration_url
        else
          sign_up(resource_name, resource)
          set_flash_message! :notice, :signed_up
          respond_with resource, location: after_sign_up_path_for(resource)
        end
      else
        track_failed_registration
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end

    private

    # Sends a successful registration to the risk endpoint and returns the verdict.
    # @param user [User]
    # @return [String] the Castle policy action: 'allow', 'challenge' or 'deny'
    def evaluate_registration(user)
      castle.risk(
        type: '$registration',
        status: '$succeeded',
        request_token: castle_request_token,
        user: { id: user.id, email: user.email }
      ).dig(:policy, :action)
    rescue Castle::Error
      # Never block a sign-up because Castle is unhappy with the request.
      'allow'
    end

    # Reports an invalid registration attempt (e.g. an email already taken) to
    # the filter endpoint.
    def track_failed_registration
      email = sign_up_params[:email]

      castle.filter(
        type: '$registration',
        status: '$failed',
        request_token: castle_request_token,
        user: { email: email },
        params: { email: email }
      )
    rescue Castle::Error
      nil
    end
  end
end
