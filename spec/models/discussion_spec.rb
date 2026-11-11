require 'rails_helper'

RSpec.describe(Discussion) do
  describe 'relationships' do
    it { is_expected.to(belong_to(:subject)) }
    it { is_expected.to(have_many(:discussion_topics).dependent(:destroy)) }
  end
end
