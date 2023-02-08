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
FactoryBot.define do
  factory :customer do
    name { Faker::Company.name }
  end
end
