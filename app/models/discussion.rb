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
class Discussion < ApplicationRecord
  belongs_to :subject, polymorphic: true

  has_many :discussion_topics, dependent: :destroy
  has_many :subscriptions, as: :record, dependent: :destroy

  has_many :comments, through: :discussion_topics
end
