# == Schema Information
#
# Table name: problem_types
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
# Indexes
#
#  index_problem_types_on_name  (name)
#
class ProblemType < ApplicationRecord
  validates :name, uniqueness: true
end
