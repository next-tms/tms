# frozen_string_literal: true

class Accessorial < ApplicationRecord
  belongs_to :shipment_accessorial, optional: true
  validates :name, presence: true, uniqueness: true
end
