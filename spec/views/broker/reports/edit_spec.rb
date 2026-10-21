require 'rails_helper'

RSpec.describe('broker/reports/edit') do
  subject { rendered }

  let(:report) { create(:report) }

  before do
    without_partial_double_verification { allow(view).to(receive(:current_user).and_return(report.created_by)) }
    assign(:columns, [ 'load_id' ])
    assign(:customer_columns, [ 'load_id' ])
    assign(:date_attributes, [ 'created_at' ])
    assign(:from, Date.new(2026, 10, 1))
    assign(:report, report)
    assign(:to, Date.new(2026, 10, 31))
    render
  end

  it { is_expected.to(include("Edit #{report.name}", broker_report_path(report))) }
  it { expect(rendered.scan(/<input[^>]*name="report\[record_type\]"[^>]*>/)).to(contain_exactly(include('value="Shipment"'))) }
  it { is_expected.to(include(Shipment.model_name.human(count: :other))) }
end
