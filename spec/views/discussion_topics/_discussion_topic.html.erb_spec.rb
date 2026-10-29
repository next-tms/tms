require 'rails_helper'

RSpec.describe('discussion_topics/_discussion_topic') do
  subject { rendered }

  let(:contact) { create(:contact, first_name: 'Ada', last_name: 'Lovelace') }
  let(:current_user) { create(:root_broker_user) }
  let(:discussion_topic) { create(:problem, title: 'Missing pickup').discussion_topic }

  before do
    discussion_topic.comments.create!(body: 'Robot note')
    discussion_topic.comments.create!(body: "Called the shipper\nNo answer", contact:)
    allow(view).to(receive(:current_user).and_return(current_user))
    render(partial: 'discussion_topics/discussion_topic', locals: { discussion_topic: })
  end

  it { is_expected.to(include('Missing pickup')) }
  it { is_expected.to(include('Robot', 'Robot note')) }
  it { is_expected.to(include('Ada Lovelace', "Called the shipper\n<br />No answer")) }
  it { is_expected.to(have_css("ul##{ActionView::RecordIdentifier.dom_id(discussion_topic, :comments)} li##{ActionView::RecordIdentifier.dom_id(discussion_topic, :new_comment)} form")) }
end
