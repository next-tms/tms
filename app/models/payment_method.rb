# frozen_string_literal: true

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
end
