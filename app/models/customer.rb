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
class Customer < ApplicationRecord
  has_many :broker_customers, dependent: :restrict_with_error

  validates :name, uniqueness: true
end
