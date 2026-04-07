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
require 'rails_helper'

RSpec.describe(Discussion) do
  describe 'relationships' do
    it { is_expected.to(belong_to(:subject)) }
    it { is_expected.to(have_many(:discussion_topics).dependent(:destroy)) }
  end
end
