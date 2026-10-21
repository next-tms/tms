require 'rails_helper'

RSpec.describe('broker/reports/index') do
  subject { rendered }

  let(:allowed) { true }
  let(:report) { create(:report) }

  before do
    assign(:presets, Report::Preset.all)
    assign(:reports, [ report ])
    allow(view).to(receive(:allowed_to?).with(:edit?, report).and_return(allowed))
    render
  end

  it { is_expected.to(include('Customer Report', 'Freight Report', report.name, ERB::Util.html_escape(report.created_by.full_name))) }
  it { is_expected.to(include("#{Shipment.model_name.human(count: :other)}, 1 column")) }
  it { is_expected.to(include(new_broker_report_path(duplicate: 'freight-report'))) }
  it { is_expected.to(include(edit_broker_report_path(report), new_broker_report_path(duplicate: report.id))) }

  context 'when not allowed to edit' do
    let(:allowed) { false }

    it { is_expected.not_to(include(edit_broker_report_path(report))) }
  end
end
