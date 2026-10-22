require 'rails_helper'

RSpec.describe('layouts/_nav') do
  subject { rendered }

  before do
    create(:setting, key: 'name', value: 'Liftoff')
    create(:setting, key: 'website_homepage', value: 'https://example.com')
  end

  context 'when signed in' do
    let(:current_user) { create(:root_broker_user) }

    before do
      allow(view).to(receive_messages(current_user:, user_signed_in?: true))
      render
    end

    it { is_expected.to(have_link('Liftoff', href: root_path)) }
  end

  context 'when signed out' do
    before do
      allow(view).to(receive(:user_signed_in?).and_return(false))
      render
    end

    it { is_expected.to(have_link('Liftoff', href: 'https://example.com')) }
  end
end
