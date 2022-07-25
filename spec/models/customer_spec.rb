# == Schema Information
#
# Table name: customers
#
# @!attribute id
#   @return []
# @!attribute name
#   @return [String]
#
# Indexes
#
#  index_customers_on_name  (name)
#
require 'rails_helper'

RSpec.describe Customer, type: :model do
  describe 'relationships' do
    it { is_expected.to have_many(:broker_customers) }
    it { is_expected.to have_many(:brokers).through(:broker_customers) }
    it { is_expected.to have_many(:customer_contacts) }
    it { is_expected.to have_many(:contacts).through(:customer_contacts) }
  end

  describe 'validations' do
    it { is_expected.to validate_uniqueness_of(:name) }
  end
end
