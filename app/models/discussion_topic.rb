# == Schema Information
#
# Table name: discussion_topics
#
# @!attribute id
#   @return []
# @!attribute contact_scope
#   @return [String]
# @!attribute topic_type
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute discussion_id
#   @return []
# @!attribute topic_id
#   @return []
#
# Indexes
#
#  index_discussion_topics_on_contact_scope  (contact_scope)
#  index_discussion_topics_on_discussion_id  (discussion_id)
#  index_discussion_topics_on_topic          (topic_type,topic_id)
#
class DiscussionTopic < ApplicationRecord
  belongs_to :discussion
  belongs_to :topic, polymorphic: true

  delegate :discussable_topic_description, to: :topic

  enum :contact_scope, { broker: 'broker', carrier: 'carrier', customer: 'customer', any: 'any' }

  has_many :comments, dependent: :destroy
  has_many :subscriptions, as: :record, dependent: :destroy

  has_many :contacts, through: :subscriptions

  validates :contact_scope, presence: true
end
