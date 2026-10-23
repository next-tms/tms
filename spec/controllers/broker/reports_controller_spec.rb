require 'rails_helper'

RSpec.describe(Broker::ReportsController) do
  subject { response }

  let(:preset) { Report::Preset.find('freight-report') }
  let(:report) { create(:report, broker: user.broker, created_by: user) }
  let(:report_params) { { columns: [ 'load_id', 'total_cost' ], name: 'Margins', record_type: 'Shipment' } }
  let(:role) { :dispatch }
  let(:user) { create(:broker_user) }

  before do
    create(:contact_role, contact: user.contact, role:)
    create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles')
    sign_in(user)
  end

  describe 'GET #index' do
    before do
      report
      get(:index)
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:presets).map(&:key)).to(eq(Report::Preset.all.map(&:key))) }
    it { expect(assigns(:reports)).to(eq([ report ])) }

    context 'when fresh' do
      before do
        request.headers['If-None-Match'] = response.etag
        get(:index)
      end

      it { is_expected.to(have_http_status(:not_modified)) }
    end

    context 'when another author is renamed' do
      let(:report) { create(:report, broker: user.broker) }

      before do
        request.headers['If-None-Match'] = response.etag
        report.created_by.update!(first_name: 'Renamed')
        get(:index)
      end

      it { is_expected.to(have_http_status(:ok)) }
    end

    context 'without a reporting role' do
      let(:role) { :carrier_relations }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'GET #new' do
    before { get(:new, params:) }

    let(:params) { {} }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:report).created_by).to(eq(user)) }
    it { expect(assigns(:report).record_class).to(be_nil) }

    context 'when fresh' do
      before do
        request.headers['If-None-Match'] = response.etag
        get(:new, params:)
      end

      it { is_expected.to(have_http_status(:not_modified)) }
    end

    context 'when fresh on a later day' do
      before do
        request.headers['If-None-Match'] = response.etag
        Timecop.travel(1.day.from_now) { get(:new, params:) }
      end

      it { is_expected.to(have_http_status(:ok)) }
    end

    context 'when fresh after a role change' do
      before do
        request.headers['If-None-Match'] = response.etag
        create(:contact_role, contact: user.contact, role: :accounts_receivable)
        get(:new, params:)
      end

      it { is_expected.to(have_http_status(:ok)) }
    end

    context 'when duplicating a preset' do
      let(:params) { { duplicate: preset.key } }

      it { expect(assigns(:report).columns).to(eq(preset.columns)) }
      it { expect(assigns(:report).date_attribute).to(eq('created_at')) }
      it { expect(assigns(:report).name).to(eq('Freight Report (Copy)')) }
      it { expect(assigns(:report).record_type).to(eq('Shipment')) }
    end

    context 'when duplicating a saved report' do
      let(:params) { { duplicate: report.id } }
      let(:report) { create(:report, broker: user.broker, columns: [ 'first_name' ], filters: { 'first_name_cont' => 'Jim' }, record_type: 'Contact') }

      it { expect(assigns(:report)).to(have_attributes(columns: [ 'first_name' ], filters: { 'first_name_cont' => 'Jim' }, record_type: 'Contact')) }
      it { expect(assigns(:report).name).to(eq("#{report.name} (Copy)")) }
      it { expect(assigns(:report)).to(be_new_record) }
    end

    context 'when duplicating another broker’s report' do
      let(:params) { { duplicate: create(:report).id } }

      it { expect(assigns(:report).record_class).to(be_nil) }
    end

    context 'with a record type' do
      let(:params) { { record_type: 'Contact' } }

      it { expect(assigns(:report).columns).to(eq(ExporterService.default_columns(Contact, user))) }
      it { expect(assigns(:date_attributes)).to(eq(assigns(:report).date_attributes(user))) }
      it { expect(assigns(:report).filters).to(eq({})) }
    end

    context 'with export filters' do
      let(:params) do
        {
          columns: [ 'load_id', 'status' ],
          filters: { active: true, pending_pickup: true },
          q: { Shipment::SEARCH_PREDICATE => 'Acme', s: 'created_at desc' },
          record_type: 'Shipment'
        }
      end

      let(:filters) do
        {
          Shipment::SEARCH_PREDICATE.to_s => 'Acme',
          'active' => 'true',
          'pending_pickup' => 'true',
          's' => 'created_at desc'
        }
      end

      it { expect(assigns(:report).columns).to(eq([ 'load_id', 'status' ])) }
      it { expect(assigns(:report).filters).to(eq(filters)) }
      it { expect(assigns(:report).record_type).to(eq('Shipment')) }
    end
  end

  describe 'POST #create' do
    before { post(:create, params:) }

    let(:params) { { report: report_params } }

    it { is_expected.to(redirect_to(broker_report_path(Report.last))) }
    it { expect(Report.last).to(have_attributes(broker: user.broker, columns: [ 'load_id', 'total_cost' ], created_by: user)) }
    it { expect(Report.last).to(have_attributes(filters: {}, record_type: 'Shipment')) }

    context 'with a date range' do
      let(:params) { { from: '2026-10-01', report: report_params.merge(date_attribute: 'created_at'), to: '2026-10-15' } }

      it { is_expected.to(redirect_to(broker_report_path(Report.last, from: '2026-10-01', to: '2026-10-15'))) }
    end

    context 'with filters' do
      let(:report_params) { super().merge(filters: { active: 'true', load_id_eq: '7', status_in: [ '', 'delivered' ] }) }

      it { expect(Report.last.filters).to(eq({ 'active' => 'true', 'load_id_eq' => '7', 'status_in' => [ 'delivered' ] })) }
    end

    context 'with a preview' do
      let(:params) { { preview: 'Preview', report: report_params } }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(assigns(:preview).headers).to(eq([ 'Load', 'Carrier Cost' ])) }
      it { expect(Report.count).to(eq(0)) }
    end

    context 'when invalid' do
      let(:report_params) { { columns: [], name: '', record_type: 'Shipment' } }

      it { is_expected.to(have_http_status(:unprocessable_content)) }
      it { expect(Report.count).to(eq(0)) }
    end

    context 'with a saved column order' do
      let(:report_params) do
        {
          column_order: [ 'status', 'shipper_address.zip_code', 'load_id' ],
          columns: [ '', 'load_id', 'status', 'total_cost', 'shipper_address.zip_code' ],
          name: 'Margins',
          record_type: 'Shipment'
        }
      end

      it { expect(Report.last.columns).to(eq([ 'status', 'shipper_address.zip_code', 'load_id', 'total_cost' ])) }
    end

    context 'without columns' do
      let(:report_params) { { columns: [ '' ], name: 'Empty', record_type: 'Shipment' } }

      it { is_expected.to(have_http_status(:unprocessable_content)) }
      it { expect(assigns(:report).columns).to(eq([])) }
    end
  end

  describe 'GET #show' do
    before { get(:show, format:, params:) }

    let(:format) { :html }
    let(:params) { { from: '2026-10-01', id: preset.key, to: '2026-10-31' } }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:preview).headers).to(eq(preset.headers.values)) }
    it { expect(assigns(:from)).to(eq(Date.new(2026, 10, 1))) }
    it { expect(assigns(:to)).to(eq(Date.new(2026, 10, 31))) }
    it { expect(response.headers['Last-Modified']).to(be_nil) }

    context 'when fresh' do
      before do
        request.headers['If-None-Match'] = response.etag
        get(:show, format:, params:)
      end

      it { is_expected.to(have_http_status(:not_modified)) }
    end

    context 'when fresh on a later day' do
      before do
        request.headers['If-None-Match'] = response.etag
        Timecop.travel(1.day.from_now) { get(:show, format:, params:) }
      end

      it { is_expected.to(have_http_status(:ok)) }
    end

    context 'when fresh after a role change' do
      before do
        request.headers['If-None-Match'] = response.etag
        create(:contact_role, contact: user.contact, role: :accounts_receivable)
        get(:show, format:, params:)
      end

      it { is_expected.to(have_http_status(:ok)) }
    end

    context 'when CSV' do
      let(:format) { :csv }

      it { expect(response.media_type).to(eq('text/csv')) }
      it { expect(response.headers['Content-Disposition']).to(include('Freight Report 2026-10-01 to 2026-10-31.csv')) }
      it { expect(response.headers['Last-Modified']).to(be_nil) }
      it { expect(CSV.parse(response.body).first).to(eq(preset.headers.values)) }

      context 'when fresh' do
        before do
          request.headers['If-None-Match'] = response.etag
          get(:show, format:, params:)
        end

        it { is_expected.to(have_http_status(:not_modified)) }
      end

      context 'without a date attribute' do
        let(:params) { { id: report.id } }

        it { expect(response.headers['Content-Disposition']).to(match(/filename="#{report.name} \d{4}-\d{2}-\d{2}T/)) }
      end
    end

    context 'when YAML' do
      let(:format) { :yaml }

      it { expect(response.media_type).to(eq('application/x-yaml')) }
      it { expect(response.headers['Content-Disposition']).to(include('Freight Report 2026-10-01 to 2026-10-31.yaml')) }
      it { expect(YAML.unsafe_load(response.body)).to(eq([])) }
    end

    context 'with an invalid date' do
      let(:params) { { from: 'yesterday', id: preset.key } }

      it { expect(assigns(:from)).to(eq(Time.current.in_time_zone('America/Los_Angeles').to_date.beginning_of_month)) }
    end

    context 'with a saved report' do
      let(:params) { { id: report.id } }

      it { expect(assigns(:report)).to(eq(report)) }
      it { expect(assigns(:preview).columns).to(eq(report.columns)) }
    end

    context 'with a dated report' do
      let(:params) { { from: from.iso8601, id: report.id, to: to.iso8601 } }
      let(:from) { today - 10 }
      let(:report) { create(:report, broker: user.broker, created_by: user, date_attribute: 'created_at') }
      let(:to) { today - 6 }
      let(:today) { Time.current.in_time_zone('America/Los_Angeles').to_date }

      it { expect(report.reload).to(have_attributes(from_days_ago: 10, to_days_ago: 6)) }

      context 'when run again without dates' do
        before { get(:show, params: { id: report.id }) }

        it { expect(assigns(:from)).to(eq(from)) }
        it { expect(assigns(:to)).to(eq(to)) }
      end

      context 'without dates' do
        let(:params) { { id: report.id } }

        it { expect(report.reload).to(have_attributes(from_days_ago: nil, to_days_ago: nil)) }
        it { expect(assigns(:from)).to(eq(today.beginning_of_month)) }
      end
    end

    context 'with an undated report' do
      let(:params) { { from: '2026-10-01', id: report.id, to: '2026-10-31' } }

      it { expect(report.reload).to(have_attributes(from_days_ago: nil, to_days_ago: nil)) }
    end

    context 'with another user’s dated report' do
      let(:params) { { from: '2026-10-01', id: report.id, to: '2026-10-31' } }
      let(:report) { create(:report, broker: user.broker, date_attribute: 'created_at') }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(assigns(:from)).to(eq(Date.new(2026, 10, 1))) }
      it { expect(report.reload).to(have_attributes(from_days_ago: nil, to_days_ago: nil)) }
    end
  end

  describe 'GET #show for another broker' do
    let(:other_report) { create(:report) }

    it { expect { get(:show, params: { id: other_report.id }) }.to(raise_error(ActiveRecord::RecordNotFound)) }
  end

  describe 'GET #edit' do
    before { get(:edit, params: { id: }) }

    let(:id) { report.id }

    it { is_expected.to(have_http_status(:ok)) }

    context 'when fresh' do
      before do
        request.headers['If-None-Match'] = response.etag
        get(:edit, params: { id: })
      end

      it { is_expected.to(have_http_status(:not_modified)) }
    end

    context 'when fresh on a later day' do
      before do
        request.headers['If-None-Match'] = response.etag
        Timecop.travel(1.day.from_now) { get(:edit, params: { id: }) }
      end

      it { is_expected.to(have_http_status(:ok)) }
    end

    context 'when a preset' do
      let(:id) { preset.key }

      it { is_expected.to(have_http_status(:not_found)) }
    end

    context 'when another user' do
      let(:report) { create(:report, broker: user.broker) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'PATCH #update' do
    before { patch(:update, params:) }

    let(:params) { { id: report.id, report: report_params } }
    let(:report) { create(:report, broker: user.broker, created_by: user, filters: { 'active' => true }) }

    it { is_expected.to(redirect_to(broker_report_path(report))) }
    it { expect(report.reload.name).to(eq('Margins')) }
    it { expect(report.reload.filters).to(eq({})) }

    context 'with a preview' do
      let(:params) { { id: report.id, preview: 'Preview', report: report_params } }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(report.reload.name).not_to(eq('Margins')) }
    end

    context 'when invalid' do
      let(:report_params) { { name: '' } }

      it { is_expected.to(have_http_status(:unprocessable_content)) }
    end

    context 'with an unchanged selection' do
      let(:columns) { [ 'status', 'shipper_address.zip_code', 'load_id' ] }
      let(:report) { create(:report, broker: user.broker, columns:, created_by: user) }
      let(:report_params) { { column_order: columns, columns: [ '', 'load_id', 'status', 'shipper_address.zip_code' ], name: 'Margins' } }

      it { expect(report.reload.columns).to(eq(columns)) }
    end

    context 'with a date range' do
      let(:params) { { from: '2026-10-01', id: report.id, report: report_params.merge(date_attribute: 'created_at'), to: '2026-10-15' } }

      it { is_expected.to(redirect_to(broker_report_path(report, from: '2026-10-01', to: '2026-10-15'))) }
    end

    context 'with another record type' do
      let(:report_params) { { name: 'Margins', record_type: 'User' } }

      it { is_expected.to(redirect_to(broker_report_path(report))) }
      it { expect(report.reload.record_type).to(eq('Shipment')) }
    end
  end

  describe 'DELETE #destroy' do
    before { delete(:destroy, params: { id: report.id }) }

    it { is_expected.to(redirect_to(broker_reports_path)) }
    it { expect(Report.exists?(report.id)).to(be(false)) }
  end
end
