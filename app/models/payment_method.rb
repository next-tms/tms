# == Schema Information
#
# Table name: payment_methods
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
class PaymentMethod < ApplicationRecord
  validates :name, presence: true

  ENUMERABLE_VALUES = {
    'Credit Card' => 'credit_card',
    'Check' => 'checking'
  }.freeze

  def enumerable_value
    ENUMERABLE_VALUES[name]
  end
end
