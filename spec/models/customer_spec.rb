require 'rails_helper'

RSpec.describe(Customer) do
  describe 'relationships' do
    it { is_expected.to(have_many(:broker_customers).dependent(:restrict_with_error)) }
  end

  describe 'validations' do
    it { is_expected.to(validate_uniqueness_of(:name)) }
  end
end
