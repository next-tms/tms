class Packaging < ApplicationRecord
  has_many :items, dependent: :restrict_with_error
  validates :name, uniqueness: true
end
