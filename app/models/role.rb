# frozen_string_literal: true

# == Schema Information
#
# Table name: roles
#
# @!attribute id
#   @return []
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
class Role < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  has_many :user_roles
  has_many :users, through: :user_roles
end
