# frozen_string_literal: true

class Packaging < ApplicationRecord
  has_many :items
  validates_uniqueness_of :name
end
