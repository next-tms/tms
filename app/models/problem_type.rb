# frozen_string_literal: true

# == Schema Information
#
# Table name: problem_types
#
# @!attribute id
#   @return []
# @!attribute code
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute role_id
#   @return []
#
# Indexes
#
#  index_problem_types_on_name     (name)
#  index_problem_types_on_role_id  (role_id)
#
# Foreign Keys
#
#  fk_rails_...  (role_id => roles.id)
#
class ProblemType < ApplicationRecord
  belongs_to :role

  # Cannot use "not" as prefix
  enum resolves_when_class_attribute_is: {
    attached: 'attached',
    blank: 'blank',
    blank_false: 'blank_false'
  }

  has_many :problems

  validates :name, uniqueness: true
end
