require 'rails_helper'

RSpec.describe(Audit) do
  describe '.ransackable_associations' do
    it { expect(described_class.ransackable_associations).to(be_empty) }
  end

  describe '.ransackable_attributes' do
    it { expect(described_class.ransackable_attributes).to(eq(['action', 'auditable_id', 'created_at'])) }
  end
end
