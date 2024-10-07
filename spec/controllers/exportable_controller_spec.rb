require 'rails_helper'

RSpec.describe(ExportableController) do
  subject { response }

  controller(ApplicationController) do
    def index = respond_with_export(BrokerCarrier.where(broker: current_user.broker))
    def show = head(:ok)

    private

    def default_render = head(:no_content)
  end

  let(:broker_carrier) { create(:broker_carrier, broker: user.broker) }
  let(:plural_model_name) { BrokerCarrier.model_name.human(count: :other) }
  let(:user) { create(:root_broker_user) }

  before { sign_in(user) }

  describe '#exportable?' do
    subject { controller.view_context }

    it { is_expected.not_to(be_exportable) }

    context 'with an action that responds with an export' do
      before { get(:index) }

      it { is_expected.to(be_exportable) }
      it { is_expected.to(have_attributes(export_record_class: BrokerCarrier)) }
    end

    context 'with an action that does not respond with an export' do
      before { get(:show, params: { id: 1 }) }

      it { is_expected.not_to(be_exportable) }
      it { is_expected.to(have_attributes(export_record_class: nil)) }
    end
  end

  describe '#send_export' do
    before do
      broker_carrier
      get(:index, format: :csv, params:)
    end

    let(:csv) { CSV.parse(response.body) }

    context 'with columns' do
      let(:params) { { columns: %w[name password] } }

      it { expect(csv.first).to(eq([ BrokerCarrier.human_attribute_name(:name) ])) }
      it { expect(csv.second).to(eq([ broker_carrier.name ])) }
    end

    context 'with columns that are not an array' do
      let(:params) { { columns: 'name' } }

      it { expect(csv.first).to(eq(ExporterService.new(BrokerCarrier.none, authorizable: user).headers)) }
    end

    context 'without columns' do
      let(:params) { {} }

      it { expect(csv.first).to(eq(ExporterService.new(BrokerCarrier.none, authorizable: user).headers)) }
    end
  end

  describe '#respond_with_export' do
    before do
      broker_carrier
      get(:index, format:)
    end

    context 'when CSV' do
      let(:format) { :csv }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.body).to(include(broker_carrier.name)) }
      it { expect(response.headers['Content-Disposition']).to(match(/filename="#{plural_model_name} .+\.csv"/)) }
      it { expect(response.headers['ETag']).to(be_present) }
      it { expect(response.media_type).to(eq('text/csv')) }
    end

    context 'when HTML' do
      let(:format) { :html }

      it { is_expected.to(have_http_status(:no_content)) }
      it { expect(assigns(:anonymous)).to(eq([ broker_carrier ])) }
      it { expect(assigns(:pagy).count).to(eq(1)) }
      it { expect(response.headers['ETag']).to(be_present) }
    end

    context 'when YAML' do
      let(:format) { :yaml }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.body).to(include(broker_carrier.name)) }
      it { expect(response.headers['Content-Disposition']).to(match(/filename="#{plural_model_name} .+\.yaml"/)) }
      it { expect(response.media_type).to(eq('application/x-yaml')) }
    end
  end
end
