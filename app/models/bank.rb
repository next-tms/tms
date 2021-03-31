# frozen_string_literal: true

class Bank < ApplicationRecord
  belongs_to :broker
  belongs_to :type, class_name: 'BankType'

  validates :name, presence: true

  def pretty_name
    @pretty_name ||= "#{name} — #{type.name} #{account_number}"
  end
end
