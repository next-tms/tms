require 'rails_helper'

RSpec.describe('broker/payments/pay') do
  subject { rendered }

  let(:broker_carrier) { build(:broker_carrier, **ach_attributes) }
  let(:ach_attributes) do
    { encrypted_ach_account_number: '1234', encrypted_ach_bank_name: 'First Bank', encrypted_ach_routing_number: '123456789' }
  end

  before do
    create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles')
    assign(:banks, [])
    assign(:payment, Payment.new(broker_carrier:))
    assign(:selected_payment_method, PaymentMethod.create!(name: 'ACH'))
    render
  end

  it { is_expected.to(have_text('ACH Details')) }
  it { is_expected.to(have_text('First Bank')) }
  it { is_expected.to(have_text('123456789')) }
  it { is_expected.to(have_text('1234')) }

  context 'without ACH details' do
    let(:ach_attributes) { {} }

    it { is_expected.not_to(have_text('ACH Details')) }
  end
end
