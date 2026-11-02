# == Schema Information
#
# Table name: customers
#
# @!attribute id
#   @return []
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_customers_on_name  (name) UNIQUE
#
require 'rails_helper'

RSpec.describe(Customer) do
  describe 'relationships' do
    it { is_expected.to(have_many(:broker_customers).dependent(:restrict_with_error)) }
  end

  describe 'validations' do
    it { is_expected.to(validate_uniqueness_of(:name)) }
  end
end
