# frozen_string_literal: true

# NOTE: the User model does not enable Devise's :recoverable module, so no
# password-reset routes are mounted. These specs therefore assert the
# controller wiring rather than exercising HTTP requests.
RSpec.describe Users::PasswordsController do
  it { expect(described_class.ancestors).to include(Devise::PasswordsController) }
  it { expect(described_class._layout).to eq 'devise' }
end
