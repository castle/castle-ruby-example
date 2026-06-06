# frozen_string_literal: true

RSpec.describe ApplicationResponder do
  it { expect(described_class.superclass).to eq ActionController::Responder }
  it { expect(described_class.ancestors).to include(Responders::FlashResponder) }
  it { expect(described_class.ancestors).to include(Responders::HttpCacheResponder) }
end
