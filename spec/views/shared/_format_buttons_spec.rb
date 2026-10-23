require 'rails_helper'

RSpec.describe('shared/_format_buttons') do
  subject { rendered }

  let(:locals) { { label: 'Download', target: [ :broker, Report::Preset.find('freight-report') ] } }

  before do
    controller.request.path_parameters.merge!(action: 'index', controller: 'broker/contacts')
    render(partial: 'shared/format_buttons', locals:)
  end

  it { is_expected.to(include('Download CSV', 'formaction="/broker/reports/freight-report.csv"')) }
  it { is_expected.to(include('Download YAML', 'formaction="/broker/reports/freight-report.yaml"')) }
  it { is_expected.not_to(include('btn-outline')) }

  context 'without a target' do
    let(:locals) { { label: 'Export' } }

    it { is_expected.to(include('Export CSV', 'formaction="/broker/contacts.csv"', 'formaction="/broker/contacts.yaml"')) }
  end
end
