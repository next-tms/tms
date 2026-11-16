class Customer < ApplicationRecord
  has_many :broker_customers, dependent: :restrict_with_error

  normalizes :legal_name, :name, with: ->(name) { name.squish }

  validates :name, uniqueness: true
end
