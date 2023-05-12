# frozen_string_literal: true

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
require 'rails_helper'

RSpec.describe(DiscussionTopic, type: :model) do
  describe 'relationships' do
    it { is_expected.to(belong_to(:discussion)) }
    it { is_expected.to(belong_to(:topic)) }
    it { is_expected.to(have_many(:comments).dependent(:destroy)) }
  end
end
