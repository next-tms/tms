# frozen_string_literal: true

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

RSpec.describe(Customer) do
  describe 'relationships' do
    it { is_expected.to(have_many(:broker_customers)) }
    it { is_expected.to(have_many(:brokers).through(:broker_customers)) }
  end

  describe 'validations' do
    it { is_expected.to(validate_uniqueness_of(:name)) }
  end
end
