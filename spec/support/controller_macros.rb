# frozen_string_literal: true

module ControllerMacros
  def with_user
    before(:each) do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      sign_in User.create!(
                email: "#{Time.now.to_f}@castle.io",
                password: Devise.friendly_token[0, 20]
              )
    end
  end
end
