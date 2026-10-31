# == Schema Information
#
# Table name: discussions
#
# @!attribute id
#   @return []
# @!attribute subject_type
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute subject_id
#   @return []
#
# Indexes
#
#  index_discussions_on_subject  (subject_type,subject_id)
#
FactoryBot.define do
  factory :discussion
end
