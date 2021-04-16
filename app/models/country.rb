# frozen_string_literal: true

class Country < ApplicationRecord
  has_many :broker_countries
  has_many :brokers, through: :broker_countries

  validates :alpha2_code, presence: true
  validates :alpha3_code, presence: true
  validates :un_code, presence: true
end
