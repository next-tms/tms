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
require 'rails_helper'

RSpec.describe(Comment) do
  describe 'relationships' do
    it { is_expected.to(belong_to(:contact)) }
    it { is_expected.to(belong_to(:discussion_topic)) }
    it { is_expected.to(validate_presence_of(:body).presence) }
  end
end
