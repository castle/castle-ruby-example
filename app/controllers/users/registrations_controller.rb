# frozen_string_literal: true

module Users
  # User registration Devise actions with integrated Castle.io risk assessment.
  class RegistrationsController < Devise::RegistrationsController
    layout 'devise'

    # Sign up with Castle filtering. A registration is anonymous activity, so the
    # attempt is filtered before the account is created. The call is recorded so
    # the next page can show the payload sent to Castle and the verdict.
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

      if castle_action(evaluate_registration_attempt) == 'deny'
        flash[:error] = t('.access_denied')
        persist_castle_results
        redirect_to new_user_registration_url
        return
      end

      resource.save
      sign_up(resource_name, resource)
      set_flash_message! :notice, :signed_up
      persist_castle_results
      respond_with resource, location: after_sign_up_path_for(resource)
    end

    private

    # Filters the registration attempt while the visitor is still anonymous,
    # before the account is created (so the email goes in params).
    # @return [Hash, nil] the Castle response, or nil when the call raised
    def evaluate_registration_attempt
      payload = {
        type: '$registration',
        status: '$attempted',
        request_token: castle_request_token,
        params: { email: resource.email }
      }
      result = castle.filter(**payload)
      record_castle_result(endpoint: 'filter', payload: payload, response: result)
      result
    rescue Castle::Error => e
      # Never block a sign-up because Castle is unhappy with the request.
      record_castle_result(endpoint: 'filter', payload: payload, error: e)
      nil
    end

    # Reports an invalid registration attempt (e.g. an email already taken) to
    # the filter endpoint, resolving any existing user via matching_user_id.
    def track_failed_registration
      email = sign_up_params[:email]
      matching_user = User.find_by(email: email)

      payload = {
        type: '$registration',
        status: '$failed',
        request_token: castle_request_token,
        params: { email: email }
      }
      payload[:matching_user_id] = matching_user.id.to_s if matching_user

      result = castle.filter(**payload)
      record_castle_result(endpoint: 'filter', payload: payload, response: result)
    rescue Castle::Error => e
      record_castle_result(endpoint: 'filter', payload: payload, error: e)
    end
  end
end
