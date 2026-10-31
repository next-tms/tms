require 'rails_helper'

RSpec.describe('broker/shipments/_member_menu') do
  subject { rendered }

  let(:current_user) { create(:root_broker_user) }
  let(:shipment) { create(:shipment, broker_carrier: nil, load_id: 4545, quote_only:) }
  let(:quote_only) { false }

  before do
    allow(view).to(receive(:current_user).and_return(current_user))
    assign(:shipment, shipment)
    render(partial: 'broker/shipments/member_menu')
  end

  it { is_expected.to(have_link('eBOL', href: '/broker/shipments/4545.ebol')) }

  context 'when the shipment is quote only' do
    let(:quote_only) { true }

    it { is_expected.not_to(have_link('eBOL')) }
  end
end
