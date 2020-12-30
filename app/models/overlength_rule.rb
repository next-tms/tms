# frozen_string_literal: true

class OverlengthRule < ApplicationRecord
  belongs_to :broker_carrier
  monetize :cost_cents, allow_nil: false
  validates_presence_of :min_length
end
