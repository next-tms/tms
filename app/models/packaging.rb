# frozen_string_literal: true

# == Schema Information
#
# Table name: packagings
#
# @!attribute id
#   @return []
# @!attribute freight_kit_type
#   @return [String]
# @!attribute name
#   @return [String]
#
# Indexes
#
#  index_packagings_on_freight_kit_type  (freight_kit_type)
#
class Packaging < ApplicationRecord
  has_many :items
  validates :name, uniqueness: true
end
