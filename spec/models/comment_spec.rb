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
require 'rails_helper'

RSpec.describe(Comment) do
  describe '#contact_full_name' do
    let(:contact) { build(:contact, first_name: 'Ada', last_name: 'Lovelace') }

    it { expect(described_class.new(contact:).contact_full_name).to(eq('Ada Lovelace')) }
    it { expect(described_class.new.contact_full_name).to(eq('Robot')) }
  end

  describe 'relationships' do
    it { is_expected.to(belong_to(:contact).optional) }
    it { is_expected.to(belong_to(:discussion_topic)) }
    it { is_expected.to(validate_presence_of(:body).presence) }
  end
end
