# frozen_string_literal: true

# Set of macros that help during controller specs
module ControllerMacros
  # Authenticates a new dummy user and signs him in
  def with_user
    let(:user) { create(:user) }

    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      sign_in user
    end
  end
end
