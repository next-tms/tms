# frozen_string_literal: true

class RateAccessorial < ApplicationRecord
  belongs_to :rate
  belongs_to :accessorial
end
