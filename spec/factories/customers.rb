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
#  index_customers_on_name  (name) UNIQUE
#
FactoryBot.define { factory(:customer) { name { Faker::Company.name } } }
