require 'rails_helper'

RSpec.describe('customer/shipments/_member_menu') do
  subject { rendered }

  let(:shipment) { create(:shipment, broker_carrier: nil, load_id: 4646, quote_only:) }
  let(:quote_only) { false }

  before do
    assign(:shipment, shipment)
    render(partial: 'customer/shipments/member_menu')
  end

  it { is_expected.to(have_link('eBOL', href: '/customer/shipments/4646.ebol')) }

  context 'when the shipment is quote only' do
    let(:quote_only) { true }

    it { is_expected.not_to(have_link('eBOL')) }
  end
end
