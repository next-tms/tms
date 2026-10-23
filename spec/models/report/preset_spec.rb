require 'rails_helper'

RSpec.describe(Report::Preset) do
  subject(:preset) { described_class.find('freight-report') }

  describe '.all' do
    it { expect(described_class.all.map(&:key)).to(eq([ 'customer-report', 'freight-report' ])) }
  end

  describe '.find' do
    it { expect(described_class.find('customer-report').name).to(eq('Customer Report')) }
    it { expect(described_class.find('unknown')).to(be_nil) }
    it { expect(described_class.find(nil)).to(be_nil) }
  end

  describe '.policy_class' do
    it { expect(described_class.policy_class).to(eq(ReportPolicy)) }
  end

  described_class::DEFINITIONS.each_key do |key|
    context "when #{key}" do
      subject(:preset) { described_class.find(key) }

      it { expect(preset.columns).to(all(satisfy { |column| ExporterService.customer_column?(Shipment, column) })) }
      it { expect(preset.columns).not_to(include('total_cost')) }
      it { expect(preset.description).to(be_present) }
    end
  end

  describe '#cache_key' do
    it { expect(preset.cache_key).to(start_with('report/presets/freight-report/')) }
    it { expect(preset.cache_key).not_to(eq(described_class.find('customer-report').cache_key)) }
  end

  describe '#columns' do
    it { expect(preset.columns).to(eq(preset.headers.keys)) }
  end

  describe '#date_attribute' do
    it { expect(preset.date_attribute).to(eq('created_at')) }
  end

  describe '#date_range?' do
    it { expect(preset.date_range?).to(be(true)) }
  end

  describe '#exporter' do
    subject(:csv) { CSV.parse(preset.exporter(authorizable, from: Date.new(2026, 10, 1), to: Date.new(2026, 10, 31)).to_csv) }

    let(:authorizable) { create(:root_broker_user) }

    let(:headers) do
      [
        'Load',
        'Origin ZIP Code',
        'Destination ZIP Code',
        'Description',
        'Density',
        'Weight (lbs)',
        'Palletized/Crated',
        'Non-Palletized/Crated',
        'Freight Class(es)',
        'Accessorials',
        'Price'
      ]
    end

    let!(:shipment) { create(:shipment, created_at: Time.utc(2026, 10, 15)) }

    before { create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles') }

    it { expect(csv.first).to(eq(headers)) }

    it { expect(csv.second.first).to(eq(shipment.load_id.to_s)) }

    context 'when customer-report' do
      subject(:preset) { described_class.find('customer-report') }

      let(:shipment) { create(:shipment, created_at: Time.utc(2026, 10, 15), delivered_at: nil) }

      it { expect(csv.size).to(eq(1)) }
      it { expect(csv.first.last).to(eq('Status')) }
    end
  end

  describe '#default_date_range' do
    let(:today) { Date.new(2026, 10, 29) }

    it { expect(preset.default_date_range(today)).to(eq([ Date.new(2026, 10, 1), today ])) }
  end

  describe '#filters' do
    it { expect(preset.filters).to(eq({})) }
    it { expect(described_class.find('customer-report').filters).to(eq({ 'status_in' => [ 'delivered' ] })) }
  end

  describe '#headers' do
    it { expect(preset.headers).to(eq(described_class::DEFINITIONS['freight-report'][:headers])) }
  end

  describe '#preset?' do
    it { expect(preset.preset?).to(be(true)) }
  end

  describe '#record_class' do
    it { expect(preset.record_class).to(eq(Shipment)) }
  end

  describe '#record_type' do
    it { expect(preset.record_type).to(eq('Shipment')) }
  end

  describe '.model_name' do
    it { expect(described_class.model_name).to(eq(Report.model_name)) }
  end

  describe '#model_name' do
    it { expect(preset.model_name).to(eq(Report.model_name)) }
  end

  describe '#persisted?' do
    it { expect(preset.persisted?).to(be(true)) }
  end

  describe '#to_model' do
    it { expect(preset.to_model).to(be(preset)) }
  end

  describe '#to_param' do
    it { expect(preset.to_param).to(eq('freight-report')) }
  end

  describe 'polymorphic routes' do
    include Rails.application.routes.url_helpers

    it { expect(polymorphic_path([ :broker, preset ])).to(eq('/broker/reports/freight-report')) }
  end
end
