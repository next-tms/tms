require 'rails_helper'

RSpec.describe('Broker reports') do
  let(:report_params) do
    {
      columns: [ '', 'load_id', 'broker_customer.office_address.city' ],
      date_attribute: 'delivered_at',
      filters: { 'active' => 'true', 'pending_delivery' => 'true' },
      name: 'Deliveries',
      record_type: 'Shipment'
    }
  end

  let(:user) { create(:root_broker_user) }

  before do
    {
      name: 'TMS',
      theme_primary_color: '#000000',
      theme_sidebar_background_color: '#ffffff',
      theme_sidebar_text_color: '#000000',
      time_zone_name: 'America/Los_Angeles'
    }.each { |key, value| create(:setting, key:, value:) }

    allow(ENV).to(receive(:fetch).and_call_original)
    allow(ENV).to(receive(:fetch).with('DOMAIN').and_return('localhost'))
    sign_in(user)
  end

  describe 'GET /broker/reports/new from the export dialog' do
    before do
      get(
        '/broker/reports/new',
        params: {
          columns: [ 'load_id', 'broker_customer.name' ],
          filters: { active: true, dispatched_by: user.id, pending_delivery: true },
          q: { Shipment::SEARCH_PREDICATE => 'Acme' },
          record_type: 'Shipment'
        },
      )
    end

    let(:record_type_inputs) { response.body.scan(/<input[^>]*name="report\[record_type\]"[^>]*>/) }

    it { expect(response).to(have_http_status(:ok)) }
    it { expect(record_type_inputs).to(contain_exactly(include('value="Shipment"'))) }
    it { expect(response.body).to(include('name="report[filters][pending_delivery]"', 'value="Acme"')) }
    it { expect(response.body).to(include('name="report[filters][dispatched_by]"', "value=\"#{user.id}\"")) }
    it { expect(response.body).to(match(/value="load_id"[^>]* checked="checked"/)) }
    it { expect(response.body).to(include('<details class="my-1" open>', 'id="shipment_report_columns_broker_customer_name"')) }
    it { expect(response.body.index('value="Save"')).to(be < response.body.index('value="Preview"')) }
    it { expect(response.body).to(include('<turbo-frame id="report-preview">')) }
  end

  describe 'POST /broker/reports' do
    before { post('/broker/reports', params:) }

    context 'when saving' do
      let(:params) { { commit: 'Save', from: '2026-10-01', report: report_params, to: '2026-10-15' } }

      it { expect(response).to(redirect_to("/broker/reports/#{Report.last.id}?from=2026-10-01&to=2026-10-15")) }

      it 'saves what the form sent' do
        expect(Report.last).to(
          have_attributes(
            columns: [ 'load_id', 'broker_customer.office_address.city' ],
            date_attribute: 'delivered_at',
            filters: { 'active' => 'true', 'pending_delivery' => 'true' },
            record_type: 'Shipment',
          ),
        )
      end
    end

    context 'when previewing' do
      let(:params) { { preview: 'Preview', report: report_params } }

      it { expect(response).to(have_http_status(:ok)) }
      it { expect(response.body).to(match(%r{<turbo-frame id="report-preview">\s*<h3 class="mt-4">Preview</h3>})) }
      it { expect(Report.count).to(eq(0)) }
    end

    context 'when previewing an invalid report' do
      let(:params) { { preview: 'Preview', report: report_params.merge(columns: [ '' ]) } }

      it { expect(response).to(have_http_status(:unprocessable_content)) }
      it { expect(response.body).to(include('Unable to preview')) }
    end

    context 'when saving an invalid report' do
      let(:params) { { commit: 'Save', report: report_params.merge(name: '') } }

      it { expect(response).to(have_http_status(:unprocessable_content)) }
      it { expect(response.body).to(include('Unable to save report')) }
      it { expect(Report.count).to(eq(0)) }
    end
  end

  describe 'PATCH /broker/reports/:id' do
    let(:report) { create(:report, created_by: user, filters: { 'active' => true }) }

    before { patch("/broker/reports/#{report.id}", params: { commit: 'Save', from: '2026-10-01', report: report_params.except(:filters), to: '2026-10-15' }) }

    it { expect(response).to(redirect_to("/broker/reports/#{report.id}?from=2026-10-01&to=2026-10-15")) }
    it { expect(report.reload).to(have_attributes(filters: {}, name: 'Deliveries')) }
  end

  describe 'GET /broker/reports/:id' do
    let(:report) { create(:report, created_by: user, date_attribute: 'created_at') }

    before { get("/broker/reports/#{report.id}") }

    it { expect(response).to(have_http_status(:ok)) }
    it { expect(response.body).to(include('Download CSV', 'Download YAML', 'name="from"', 'name="to"')) }
    it { expect(response.body).not_to(include('btn-outline')) }
  end
end
