# frozen_string_literal: true

# == Schema Information
#
# Table name: bank_types
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
class BankType < ApplicationRecord
  validates :name, presence: true
end
