# frozen_string_literal: true

# Set of macros that help during controller specs
module ControllerMacros
  # Authenticates a new dummy user and signs him in
  def with_user
    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      sign_in User.create!(
        email: "#{Time.now.to_f}@castle.io",
        password: Devise.friendly_token[0, 20]
      )
    end
  end
end
