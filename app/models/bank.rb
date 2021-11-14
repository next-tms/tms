# frozen_string_literal: true

# == Schema Information
#
# Table name: banks
#
# @!attribute id
#   @return []
# @!attribute account_number
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute broker_id
#   @return []
# @!attribute type_id
#   @return []
#
# Indexes
#
#  index_banks_on_broker_id  (broker_id)
#  index_banks_on_type_id    (type_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_id => brokers.id)
#  fk_rails_...  (type_id => bank_types.id)
#
class Bank < ApplicationRecord
  belongs_to :broker
  belongs_to :type, class_name: 'BankType'

  has_many :payments

  validates :name, presence: true

  def pretty_name
    @pretty_name ||= "#{name} — #{type.name} #{account_number}"
  end
end
