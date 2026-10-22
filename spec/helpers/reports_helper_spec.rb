require 'rails_helper'

RSpec.describe(ReportsHelper) do
  let(:user) { create(:broker_user) }

  before { without_partial_double_verification { allow(helper).to(receive(:current_user).and_return(user)) } }

  describe '#report_filter_label' do
    it { expect(helper.report_filter_label(Shipment, 's')).to(eq('Sort')) }
    it { expect(helper.report_filter_label(Shipment, 'pending_pickup')).to(eq('Pending pickup')) }
    it { expect(helper.report_filter_label(Shipment, Shipment::SEARCH_PREDICATE.to_s)).to(eq('Search')) }
    it { expect(helper.report_filter_label(Shipment, 'created_at_gteq')).to(eq('Created at gteq')) }
    it { expect(helper.report_filter_label(Contact, 'first_name_or_last_name_cont')).to(eq('Search')) }
  end

  describe '#report_filter_value' do
    it { expect(helper.report_filter_value([ 'booked', 'delivered' ])).to(eq('booked, delivered')) }
    it { expect(helper.report_filter_value({ 'a' => 1 })).to(eq('{"a":1}')) }
    it { expect(helper.report_filter_value(true)).to(eq('Yes')) }
    it { expect(helper.report_filter_value('true')).to(eq('Yes')) }
    it { expect(helper.report_filter_value('Jimmy')).to(eq('Jimmy')) }
  end

  describe '#report_internal_columns' do
    let(:report) { build(:report, columns: [ 'load_id', 'total_cost', 'broker_carrier.broker_customer.name' ]) }

    it { expect(helper.report_internal_columns(report)).to(eq([ 'total_cost', 'broker_carrier.broker_customer.name' ])) }
  end

  describe '#report_record_name' do
    it { expect(helper.report_record_name(Shipment)).to(eq(Shipment.model_name.human(count: :other))) }
  end
end
