# frozen_string_literal: true

class CarrierArea < ApplicationRecord
  belongs_to :carrier

  belongs_to :from_area, class_name: 'Area'
  belongs_to :to_area, class_name: 'Area'
end
