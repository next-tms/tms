require 'rails_helper'

RSpec.describe(ApplicationHelper) do
  describe '#homepage' do
    subject { helper.homepage }

    it { is_expected.to(eq(root_path)) }

    context 'when website_homepage is set' do
      before { create(:setting, key: 'website_homepage', value: 'https://example.com') }

      it { is_expected.to(eq('https://example.com')) }
    end
  end
end
