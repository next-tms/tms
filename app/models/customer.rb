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
class Customer < ApplicationRecord
  class << self
    def ransackable_attributes(_auth_object = nil)
      ['name']
    end

    def ransackable_associations(_auth_object = nil)
      []
    end
  end

  has_many :broker_customers, dependent: :restrict_with_error

  validates :name, uniqueness: true
end
