require 'rails_helper'

RSpec.describe(DiscussionTopic) do
  describe 'relationships' do
    it { is_expected.to(belong_to(:discussion)) }
    it { is_expected.to(belong_to(:topic)) }
    it { is_expected.to(have_many(:comments).dependent(:destroy)) }
  end
end
