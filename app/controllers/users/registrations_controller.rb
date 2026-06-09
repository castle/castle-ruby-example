# frozen_string_literal: true

module Users
  # User registration Devise actions with integrated Castle.io risk assessment.
  class RegistrationsController < Devise::RegistrationsController
    layout 'devise'

    # Sign up with Castle filtering. A registration is anonymous activity, so the
    # attempt is filtered before the account is created.
    # @note A 'challenge' verdict is treated as 'allow' here; a real app would
    #   step up to MFA. 'deny' blocks the sign-up before the account is created.
    def create
      build_resource(sign_up_params)

      unless resource.valid?
        track_failed_registration
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
        return
      end

      if evaluate_registration_attempt == 'deny'
        flash[:error] = t('.access_denied')
        redirect_to new_user_registration_url
        return
      end

      resource.save
      sign_up(resource_name, resource)
      set_flash_message! :notice, :signed_up
      respond_with resource, location: after_sign_up_path_for(resource)
    end

    private

    # Filters the registration attempt while the visitor is still anonymous,
    # before the account is created (so the email goes in params).
    # @return [String] the Castle policy action: 'allow', 'challenge' or 'deny'
    def evaluate_registration_attempt
      castle.filter(
        type: '$registration',
        status: '$attempted',
        request_token: castle_request_token,
        params: { email: resource.email }
      ).dig(:policy, :action)
    rescue Castle::Error
      # Never block a sign-up because Castle is unhappy with the request.
      'allow'
    end

    # Reports an invalid registration attempt (e.g. an email already taken) to
    # the filter endpoint, resolving any existing user via matching_user_id.
    def track_failed_registration
      email = sign_up_params[:email]
      matching_user = User.find_by(email: email)

      options = {
        type: '$registration',
        status: '$failed',
        request_token: castle_request_token,
        params: { email: email }
      }
      options[:matching_user_id] = matching_user.id if matching_user

      castle.filter(**options)
    rescue Castle::Error
      nil
    end
  end
end
