# frozen_string_literal: true

# TODO: Remove after regression testing
# Unused since 20220912051146 migration
class BankType < ApplicationRecord
  validates :name, presence: true
end
