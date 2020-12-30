# frozen_string_literal: true

class Terminal < ApplicationRecord
  belongs_to :address
  belongs_to :carrier

  phony_normalize :phone, default_country_code: 'US'
end
