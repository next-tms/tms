# frozen_string_literal: true

class CustomerContact < ApplicationRecord
  belongs_to :broker
  validates :broker, presence: true

  belongs_to :customer
  validates :customer, presence: true

  belongs_to :contact
  validates :contact, presence: true

  accepts_nested_attributes_for :contact
end
