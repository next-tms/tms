require 'rails_helper'

RSpec.describe('broker/reports/show') do
  subject { rendered }

  let(:from) { Date.new(2026, 10, 1) }
  let(:report) { Report::Preset.find('freight-report') }
  let(:shipments) { [] }
  let(:to) { Date.new(2026, 10, 31) }
  let(:user) { create(:root_broker_user) }

  before do
    create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles')
    shipments
    assign(:customer_columns, ExporterService.customer_columns(report.record_class))
    assign(:from, from)
    assign(:preview, report.exporter(user, from:, to:))
    assign(:report, report)
    assign(:to, to)
    allow(view).to(receive(:allowed_to?).and_return(true))
    render
  end

  it { is_expected.to(include('Freight Report', report.description, 'Download CSV', 'Download YAML', 'Duplicate')) }
  it { is_expected.to(include("No #{Shipment.model_name.human(count: :other).downcase} match")) }
  it { is_expected.to(include(new_broker_report_path(duplicate: report.key))) }
  it { is_expected.to(include('value="2026-10-01"', 'value="2026-10-31"')) }
  it { is_expected.not_to(include('internal columns')) }

  context 'with shipments' do
    let(:shipments) { [ create(:shipment, broker: user.broker, created_at: Time.utc(2026, 10, 15)) ] }

    it { is_expected.to(include(*report.headers.values, shipments.first.load_id.to_s)) }
  end

  context 'with internal columns' do
    let(:report) { create(:report, broker: user.broker, columns: [ 'load_id', 'total_cost' ]) }

    it { is_expected.to(include('internal columns', 'Carrier Cost', edit_broker_report_path(report), new_broker_report_path(duplicate: report.id))) }
  end

  context 'without a date attribute' do
    let(:report) { create(:report, broker: user.broker, record_type: 'Contact', columns: [ 'first_name' ]) }

    it { is_expected.not_to(include('name="from"', 'name="to"', 'value="Preview"')) }
    it { is_expected.to(include(Contact.human_attribute_name(:first_name), user.contact.first_name)) }
  end
end
