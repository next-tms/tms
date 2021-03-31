# frozen_string_literal: true

class BankType < ApplicationRecord
  validates :name, presence: true
end
