require 'rails_helper'

RSpec.describe('broker/reports/new') do
  subject { rendered }

  let(:date_attribute) { nil }
  let(:filters) { {} }
  let(:record_type) { 'Shipment' }
  let(:report) { Report.new(date_attribute:, filters:, record_type:) }
  let(:user) { create(:broker_user) }

  before do
    without_partial_double_verification { allow(view).to(receive(:current_user).and_return(user)) }
    assign(:date_attributes, [ 'created_at', 'delivered_at' ])
    assign(:from, Date.new(2026, 10, 1))
    assign(:report, report)
    assign(:to, Date.new(2026, 10, 31))
    render
  end

  it { is_expected.to(include('New Report', Shipment.model_name.human(count: :other), 'Carrier Cost', 'Internal')) }
  it { is_expected.to(include('name="preview"', 'value="Save"')) }
  it { is_expected.to(include('<option value="delivered_at">', 'None')) }
  it { is_expected.not_to(include('value="2026-10-01"')) }
  it { is_expected.not_to(include('First 25')) }

  context 'with a date attribute' do
    let(:date_attribute) { 'created_at' }

    it { is_expected.to(include('value="2026-10-01"', 'value="2026-10-31"')) }
  end

  context 'with filters' do
    let(:filters) { { 'pending_pickup' => true, 's' => 'created_at desc', 'status_in' => [ 'booked' ] } }

    it { is_expected.to(include('Pending pickup', 'name="report[filters][pending_pickup]"')) }
    it { is_expected.to(include('Sort', 'name="report[filters][s]"', 'value="created_at desc"')) }
    it { is_expected.to(include('name="report[filters][status_in][]"', 'value="booked"')) }
  end

  context 'without a record type' do
    let(:record_type) { nil }

    it { is_expected.to(include('What should this report list?')) }
    it { is_expected.to(include(*Report::RECORD_TYPES.map { |type| ERB::Util.html_escape(new_broker_report_path(record_type: type)) })) }
    it { is_expected.not_to(include('value="Save"')) }
  end
end
