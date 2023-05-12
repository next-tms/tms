# frozen_string_literal: true

# == Schema Information
#
# Table name: comments
#
# @!attribute id
#   @return []
# @!attribute body
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute contact_id
#   @return []
# @!attribute discussion_topic_id
#   @return []
#
# Indexes
#
#  index_comments_on_contact_id           (contact_id)
#  index_comments_on_discussion_topic_id  (discussion_topic_id)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (discussion_topic_id => discussion_topics.id)
#
class Comment < ApplicationRecord
  belongs_to :discussion_topic
  belongs_to :contact
  
  validates :body, presence: true
end
