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
class Customer < ApplicationRecord
  class << self
    def ransackable_attributes(auth_object = nil)
      ['name']
    end

    def ransackable_associations(auth_object = nil)
      []
    end
  end

  has_many :broker_customers
  has_many :brokers, through: :broker_customers

  has_many :shipments

  has_many :location_addresses, class_name: 'Address'

  has_many :broker_accessorials
  accepts_nested_attributes_for :broker_accessorials, allow_destroy: true, reject_if: :all_blank

  validates :name, uniqueness: true
end
