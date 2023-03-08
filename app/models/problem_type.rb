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
# @!attribute resolvable_class_attribute_name
#   @return [String]
# @!attribute resolvable_class_name
#   @return [String]
# @!attribute resolvable_class_since_attribute_name
#   @return [String]
# @!attribute resolves_when_class_attribute_is
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute role_id
#   @return []
#
# @deprecated Removed, only exists for historical reasons
class ProblemType < ApplicationRecord
end
