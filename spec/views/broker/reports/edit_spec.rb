require 'rails_helper'

RSpec.describe('broker/reports/edit') do
  subject { rendered }

  let(:report) { create(:report) }

  before do
    without_partial_double_verification { allow(view).to(receive(:current_user).and_return(report.created_by)) }
    allow(view).to(receive(:allowed_to?).and_return(true))
    assign(:date_attributes, [ 'created_at' ])
    assign(:from, Date.new(2026, 10, 1))
    assign(:report, report)
    assign(:to, Date.new(2026, 10, 31))
    assign(:today, Date.new(2026, 10, 22))
    render
  end

  it { is_expected.to(include(report.name, "action=\"/broker/reports/#{report.id}\"")) }
  it { expect(rendered.scan(/<input[^>]*name="report\[record_type\]"[^>]*>/)).to(contain_exactly(include('value="Shipment"'))) }
  it { is_expected.to(include(Shipment.model_name.human(count: :other))) }
  it { is_expected.to(include('class="nav-link reports-show"', 'class="nav-link reports-edit"', 'Duplicate')) }
  it { is_expected.to(include('class="btn btn-danger"', 'value="delete"')) }
  it { expect(rendered.scan(/name="report\[column_order\]\[\]" value="([^"]+)"/).flatten).to(eq(report.columns)) }
end
