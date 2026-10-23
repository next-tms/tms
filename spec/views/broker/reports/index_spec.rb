require 'rails_helper'

RSpec.describe('broker/reports/index') do
  subject { rendered }

  let(:report) { create(:report) }

  before do
    assign(:presets, Report::Preset.all)
    assign(:reports, [ report ])
    render
  end

  it { is_expected.to(include('Customer Report', 'Freight Report', report.name, ERB::Util.html_escape(report.created_by.full_name))) }
  it { is_expected.to(include('Pre-built', Shipment.model_name.human(count: :other))) }
  it { is_expected.to(include('href="/broker/reports/new"', 'Add')) }
  it { is_expected.to(include('href="/broker/reports/freight-report"', "href=\"/broker/reports/#{report.id}\"")) }
  it { is_expected.to(include('class="nav-link reports-index"')) }
  it { expect(rendered.split('<h2>').last.scan(/<th\b[^>]*>/)).to(all(include('text-nowrap'))) }
  it { is_expected.not_to(include('btn-sm', 'btn-outline', 'Delete')) }
end
