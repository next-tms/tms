# frozen_string_literal: true

class BrokerCountry < ApplicationRecord
  belongs_to :broker
  belongs_to :country
end
