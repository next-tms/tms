class Terminal < ApplicationRecord
  class << self
    def ransackable_associations(_auth_object = nil)
      ['address', 'carrier']
    end
  end

  belongs_to :address
  belongs_to :carrier

  phony_normalize :phone, default_country_code: 'US'
end
