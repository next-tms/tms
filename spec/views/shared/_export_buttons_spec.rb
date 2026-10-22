require 'rails_helper'

RSpec.describe('shared/_export_buttons') do
  subject { rendered }

  let(:allowed) { true }
  let(:export_record_class) { Contact }
  let(:user) { create(:broker_user) }

  before do
    controller.request.path_parameters.merge!(action: 'index', controller: 'broker/contacts')
    controller.request.query_parameters.merge!(columns: [ 'email' ], page: '2', q: { first_name_or_last_name_cont: 'Jimmy' })

    without_partial_double_verification do
      allow(view).to(
        receive_messages(
          allowed_to?: allowed,
          current_user: user,
          export_record_class:,
          export_scopes: [ 'active', 'pending_pickup' ],
          exportable?: export_record_class.present?,
        ),
      )
    end

    render(partial: 'shared/export_buttons')
  end

  it { is_expected.to(include('Create Report', "formaction=\"#{new_broker_report_path}\"")) }
  it { is_expected.to(include('name="record_type" value="Contact"')) }
  it { is_expected.to(include('name="scopes[]" value="active"', 'name="scopes[]" value="pending_pickup"')) }

  context 'when not allowed to create reports' do
    let(:allowed) { false }

    it { is_expected.not_to(include('Create Report', 'name="record_type"')) }
    it { is_expected.to(include('Export CSV')) }
  end

  it { is_expected.to(include('data-bs-target="#export-modal"', 'id="export-modal"')) }
  it { is_expected.to(include('Export CSV', 'Export YAML')) }
  it { is_expected.to(include('action="/broker/contacts.csv"', 'formaction="/broker/contacts.yaml"')) }
  it { is_expected.to(include('name="q[first_name_or_last_name_cont]" value="Jimmy"')) }
  it { is_expected.not_to(include('name="page"')) }

  it 'lists every available column' do
    ExporterService.available_columns(Contact, user).each do |column|
      expect(rendered).to(include("value=\"#{column}\""))
    end
  end

  it 'checks the default columns' do
    ExporterService.default_columns(Contact, user).each do |column|
      expect(rendered).to(match(/value="#{Regexp.escape(column)}"[^>]* checked="checked"/))
    end
  end

  context 'when not exportable' do
    let(:export_record_class) { nil }

    it { is_expected.not_to(include('Export CSV', 'Export YAML', 'export-modal')) }
  end
end
