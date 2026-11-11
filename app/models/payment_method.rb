class PaymentMethod < ApplicationRecord
  validates :name, presence: true

  ENUMERABLE_VALUES = { 'Credit Card' => 'credit_card', 'Check' => 'checking' }.freeze

  def enumerable_value
    ENUMERABLE_VALUES[name]
  end
end
