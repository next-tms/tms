require 'rails_helper'

RSpec.describe(Comment) do
  describe 'relationships' do
    it { is_expected.to(belong_to(:contact)) }
    it { is_expected.to(belong_to(:discussion_topic)) }
    it { is_expected.to(validate_presence_of(:body).presence) }
  end
end
