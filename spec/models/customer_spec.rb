require 'rails_helper'

RSpec.describe(Customer) do
  describe 'normalizations' do
    it { expect(described_class.normalize_value_for(:legal_name, " Acme \n Holdings, LLC ")).to(eq('Acme Holdings, LLC')) }
    it { expect(described_class.normalize_value_for(:name, '   Acme  Freight ')).to(eq('Acme Freight')) }
  end

  describe 'relationships' do
    it { is_expected.to(have_many(:broker_customers).dependent(:restrict_with_error)) }
  end

  describe 'validations' do
    it { is_expected.to(validate_uniqueness_of(:name)) }
  end
end
