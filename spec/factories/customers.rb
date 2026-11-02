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
FactoryBot.define { factory(:customer) { name { Faker::Company.name } } }
