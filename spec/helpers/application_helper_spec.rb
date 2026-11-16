require 'rails_helper'

RSpec.describe(ApplicationHelper) do
  describe '#copyright' do
    subject { helper.copyright }

    before { stub_const('ApplicationHelper::COPYRIGHT', 'Copyright © 2021-2026 Example LLC') }

    it { is_expected.to(eq('Copyright © 2021-2026 Example LLC')) }
  end

  describe '#homepage' do
    subject { helper.homepage }

    it { is_expected.to(eq(root_path)) }

    context 'when website_homepage is set' do
      before { create(:setting, key: 'website_homepage', value: 'https://example.com') }

      it { is_expected.to(eq('https://example.com')) }
    end
  end
end
