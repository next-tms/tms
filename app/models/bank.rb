# frozen_string_literal: true

class Bank < ApplicationRecord
  belongs_to :broker
  belongs_to :type, class_name: 'BankType'

  has_many :payments

  validates :name, presence: true

  def pretty_name
    @pretty_name ||= "#{name} — #{type.name} #{account_number}"
  end
end
