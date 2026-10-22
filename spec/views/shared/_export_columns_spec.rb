require 'rails_helper'

RSpec.describe('shared/_export_columns') do
  subject { rendered }

  let(:association) { nil }
  let(:selected) { [ 'load_id', 'broker_customer.office_address.city' ] }
  let(:user) { create(:broker_user) }

  before do
    without_partial_double_verification { allow(view).to(receive(:current_user).and_return(user)) }
    render(partial: 'shared/export_columns', locals: { association:, mark_internal: true, name: 'columns[]', record_class: Shipment, selected: })
  end

  it { is_expected.to(match(/value="load_id"[^>]* checked="checked"/)) }
  it { is_expected.not_to(match(/value="pro"[^>]* checked="checked"/)) }
  it { is_expected.to(include('Carrier Cost', 'Internal')) }
  it { is_expected.to(include('<details class="ms-3 my-1" open>', 'Broker customer')) }
  it { is_expected.to(include('<details class="ms-3 my-1">', 'Shipper address')) }
  it { is_expected.to(include('loading="lazy"', 'selected%5B%5D=broker_customer.office_address.city')) }

  context 'with an association' do
    let(:association) { 'broker_customer.office_address' }

    it { is_expected.to(match(/value="broker_customer.office_address.city"[^>]* checked="checked"/)) }
    it { is_expected.not_to(include('<details')) }
  end
end
