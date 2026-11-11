require 'rails_helper'

RSpec.describe('layouts/_operator_notice') do
  subject { rendered }

  let(:attributes) { { action_url: 'https://pay.example.com', message: 'Please call us', status: 'past_due' } }
  let(:current_user) { create(:broker_user).tap { |user| user.add_role(:accounting) } }
  let(:operator_notice) { OperatorNotice.new(attributes) }

  before do
    allow(view).to(receive(:current_user).and_return(current_user))
    render(partial: 'layouts/operator_notice', locals: { operator_notice: })
  end

  it { is_expected.to(have_css('.alert-warning', text: 'Please call us')) }
  it { is_expected.to(have_link('Learn More', href: 'https://pay.example.com')) }

  context 'with a broker user without the accounting role' do
    let(:current_user) { create(:broker_user).tap { |user| user.add_role(:dispatch) } }

    it { is_expected.not_to(have_text('Please call us')) }
  end

  context 'with a carrier user' do
    let(:current_user) { build(:carrier_user) }

    it { is_expected.not_to(have_text('Please call us')) }
  end

  context 'with a customer user' do
    let(:current_user) { build(:customer_user) }

    it { is_expected.not_to(have_text('Please call us')) }
  end

  context 'without a notice' do
    let(:operator_notice) { nil }

    it { is_expected.to(be_blank) }
  end

  context 'without an action URL' do
    let(:attributes) { { message: 'Please call us', status: 'past_due' } }

    it { is_expected.not_to(have_link('Learn More')) }
  end
end
