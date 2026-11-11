require 'rails_helper'

RSpec.describe(ContactRole) do
  describe 'relationships' do
    it { is_expected.to(belong_to(:contact)) }
  end

  describe 'validations' do
    it { is_expected.to(validate_presence_of(:role)) }
  end

  describe '#role' do
    context 'when super is nil' do
      let(:record) { build(:contact_role, role: nil) }

      it { expect(record.role).to(be_nil) }
    end

    context 'when super is not nil' do
      let(:record) { build(:contact_role) }

      it { expect(record.role).not_to(be_nil) }
    end
  end
end
