# frozen_string_literal: true

# == Schema Information
#
# Table name: banks
#
# @!attribute id
#   @return []
# @!attribute account_number
#   @return [String]
# @!attribute kind
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute broker_id
#   @return []
# @!attribute quickbooks_account_id
#   @return [Integer]
#
# Indexes
#
#  index_banks_on_broker_id  (broker_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_id => brokers.id)
#
class Bank < ApplicationRecord
  include Bank::QuickbooksSyncable

  belongs_to :broker

  enum kind: { checking: 'checking', credit_card: 'credit_card' }

  has_many :payments

  validates :name, presence: true

  def pretty_name
    @pretty_name ||= "#{name} — #{kind.titleize} #{account_number}"
  end

  def applicable_payment_method
    PaymentMethod.all.find { |p| p.enumerable_value == kind }
  end
end
