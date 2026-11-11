class Customer < ApplicationRecord
  has_many :broker_customers, dependent: :restrict_with_error

  validates :name, uniqueness: true
end
