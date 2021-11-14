# frozen_string_literal: true

# == Schema Information
#
# Table name: packagings
#
# @!attribute id
#   @return []
# @!attribute interstellar_type
#   @return [String]
# @!attribute name
#   @return [String]
#
# Indexes
#
#  index_packagings_on_interstellar_type  (interstellar_type)
#
class Packaging < ApplicationRecord
  has_many :items
  validates_uniqueness_of :name
end
