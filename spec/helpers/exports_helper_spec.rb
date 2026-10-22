require 'rails_helper'

RSpec.describe(ExportsHelper) do
  describe '#export_column_label' do
    it { expect(helper.export_column_label(Shipment, 'total_cost')).to(eq('Carrier Cost')) }
    it { expect(helper.export_column_label(Shipment, 'broker_customer.office_address.city')).to(eq('City')) }
    it { expect(helper.export_column_label(Shipment, 'load_id', mark_internal: true)).to(eq('Load')) }
    it { expect(helper.export_column_label(Shipment, 'total_cost', mark_internal: true)).to(include('Carrier Cost', 'Internal')) }
  end

  describe '#export_column_id' do
    it { expect(helper.export_column_id(Shipment, 'columns[]', 'broker_customer.name')).to(eq('shipment_columns_broker_customer_name')) }
    it { expect(helper.export_column_id(BrokerCarrier, 'columns[]', 'broker_customer.name')).to(eq('broker_carrier_columns_broker_customer_name')) }
  end

  describe '#export_columns_frame_id' do
    it { expect(helper.export_columns_frame_id(Shipment, 'broker_customer.office_address')).to(eq('export-columns-shipment-broker_customer-office_address')) }
  end

  describe '#export_modal_id' do
    it { expect(helper.export_modal_id(BrokerCustomer)).to(eq('export-modal-broker_customer')) }
  end

  describe '#export_hidden_fields' do
    subject(:fields) { helper.export_hidden_fields }

    before do
      controller.request.query_parameters.merge!(
        columns: [ 'email' ],
        page: '2',
        q: { first_name_or_last_name_cont: 'Jimmy', s: 'first_name desc' },
      )
    end

    it { is_expected.to(include('<input type="hidden" name="q[first_name_or_last_name_cont]" value="Jimmy"')) }
    it { is_expected.to(include('<input type="hidden" name="q[s]" value="first_name desc"')) }
    it { is_expected.not_to(include('name="columns[]"')) }
    it { is_expected.not_to(include('name="page"')) }

    context 'without query parameters' do
      before { controller.request.query_parameters.clear }

      it { is_expected.to(eq('')) }
    end
  end

  describe '#query_hidden_fields' do
    subject(:fields) { helper.query_hidden_fields(query, namespace) }

    let(:namespace) { nil }
    let(:query) { { 'active' => true, 'status_in' => [ 'booked', 'delivered' ] } }

    it { is_expected.to(include('<input type="hidden" name="active" value="true"')) }
    it { is_expected.to(include('name="status_in[]" value="booked"', 'name="status_in[]" value="delivered"')) }

    context 'with a namespace' do
      let(:namespace) { 'report[filters]' }

      it { is_expected.to(include('name="report[filters][active]" value="true"', 'name="report[filters][status_in][]" value="booked"')) }
    end
  end
end
