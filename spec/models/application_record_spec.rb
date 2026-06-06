# frozen_string_literal: true

RSpec.describe ApplicationRecord do
  it { expect(described_class.abstract_class).to be true }
  it { expect(described_class.superclass).to eq ActiveRecord::Base }
end
