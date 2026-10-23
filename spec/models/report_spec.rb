require 'rails_helper'

RSpec.describe(Report) do
  subject(:report) { build(:report) }

  before { create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles') }

  describe 'relationships' do
    it { is_expected.to(belong_to(:created_by).class_name('User')) }
  end

  describe 'validations' do
    it { is_expected.to(be_valid) }
    it { is_expected.to(validate_inclusion_of(:record_type).in_array(described_class::RECORD_TYPES)) }
    it { is_expected.to(validate_presence_of(:columns)) }
    it { is_expected.to(validate_presence_of(:name)) }
    it { is_expected.to(validate_uniqueness_of(:name)) }

    context 'with an unknown column' do
      subject(:report) { build(:report, columns: [ 'load_id', 'destroy' ]) }

      it { is_expected.not_to(be_valid) }
    end

    context 'with a broker-only column' do
      subject(:report) { build(:report, columns: [ 'total_cost' ]) }

      it { is_expected.to(be_valid) }
    end

    context 'with a column from another record type' do
      subject(:report) { build(:report, columns: [ 'first_name' ], record_type: 'Contact') }

      it { is_expected.to(be_valid) }
    end

    context 'with a date attribute' do
      subject(:report) { build(:report, date_attribute: 'delivered_at') }

      it { is_expected.to(be_valid) }
    end

    context 'with an unknown date attribute' do
      subject(:report) { build(:report, date_attribute: 'load_id') }

      it { is_expected.not_to(be_valid) }
    end

    context 'with filters' do
      subject(:report) { build(:report, filters: { 'active' => true, 'load_id_eq' => '7', 'status_in' => [ 'delivered' ] }) }

      it { is_expected.to(be_valid) }
    end

    context 'with an unknown filter' do
      subject(:report) { build(:report, filters: { 'destroy_eq' => '1' }) }

      it { is_expected.not_to(be_valid) }
    end
  end

  describe '#columns' do
    subject(:report) { build(:report, columns: [ '', 'load_id', :status ]) }

    it { expect(report.columns).to(eq([ 'load_id', 'status' ])) }
  end

  describe '#date_attribute' do
    it { expect(build(:report, date_attribute: '').date_attribute).to(be_nil) }
  end

  describe '#date_attributes' do
    let(:user) { create(:root_broker_user) }

    it { expect(report.date_attributes(user)).to(include('created_at', 'delivered_at', 'picked_up_at')) }
    it { expect(report.date_attributes(user)).not_to(include('load_id')) }
  end

  describe '#default_date_range' do
    let(:today) { Date.new(2026, 10, 29) }

    it { expect(report.default_date_range(today)).to(eq([ Date.new(2026, 10, 1), today ])) }

    context 'with a remembered range' do
      subject(:report) { build(:report, from_days_ago: 10, to_days_ago: 6) }

      it { expect(report.default_date_range(today)).to(eq([ Date.new(2026, 10, 19), Date.new(2026, 10, 23) ])) }
    end
  end

  describe '#remember_date_range' do
    subject(:report) { create(:report) }

    let(:today) { Date.new(2026, 10, 22) }

    before { report.remember_date_range(Date.new(2026, 10, 12), Date.new(2026, 10, 16), today) }

    it { expect(report.reload).to(have_attributes(from_days_ago: 10, to_days_ago: 6)) }
    it { expect(report.reload.default_date_range(Date.new(2026, 10, 29))).to(eq([ Date.new(2026, 10, 19), Date.new(2026, 10, 23) ])) }
    it { expect { report.remember_date_range(Date.new(2026, 10, 12), Date.new(2026, 10, 16), today) }.not_to(change { report.reload.updated_at }) }

    context 'when the report is invalid' do
      before { report.columns = [ 'destroy' ] }

      it { expect(report.remember_date_range(Date.new(2026, 10, 1), today, today)).to(be(false)) }
    end
  end

  describe '#date_range?' do
    it { expect(report.date_range?).to(be(false)) }
    it { expect(build(:report, date_attribute: 'created_at').date_range?).to(be(true)) }
  end

  describe '#exporter' do
    subject(:exporter) { report.exporter(user, limit: 1) }

    let(:report) { build(:report, columns: [ 'load_id', 'total_cost' ]) }
    let(:user) { create(:root_broker_user) }

    before { create_list(:shipment, 2) }

    it { expect(exporter.columns).to(eq([ 'load_id', 'total_cost' ])) }
    it { expect(exporter.records.size).to(eq(1)) }
  end

  describe '#filters' do
    subject(:report) { build(:report, filters: { active: 'true', load_id_eq: '', status_in: [ '', 'delivered' ] }) }

    it { expect(report.filters).to(eq({ 'active' => 'true', 'status_in' => [ 'delivered' ] })) }
    it { expect(described_class.new.filters).to(eq({})) }
  end

  describe '#headers' do
    it { expect(report.headers).to(eq({})) }
  end

  describe '#preset?' do
    it { expect(report.preset?).to(be(false)) }
  end

  describe '#record_class' do
    it { expect(report.record_class).to(eq(Shipment)) }
    it { expect(build(:report, record_type: 'Contact').record_class).to(eq(Contact)) }
    it { expect(build(:report, record_type: 'User').record_class).to(be_nil) }
  end

  describe '#records' do
    subject { report.records(user, from:, to:).to_a }

    let(:broker_customer) { create(:broker_customer) }
    let(:date_attribute) { nil }
    let(:filters) { {} }
    let(:from) { Date.new(2026, 10, 1) }
    let(:report) { build(:report, date_attribute:, filters:) }
    let(:to) { Date.new(2026, 10, 31) }
    let(:user) { create(:root_broker_user) }

    let!(:delivered_in_month) do
      create(:shipment, created_at: Time.utc(2026, 10, 1, 6), delivered_at: Time.utc(2026, 10, 20))
    end

    let!(:first_of_month) do
      create(:shipment, broker_customer:, created_at: Time.utc(2026, 10, 1, 7), delivered_at: Time.utc(2026, 9, 30))
    end

    let!(:last_of_month) do
      create(:shipment, created_at: Time.utc(2026, 11, 1, 6), delivered_at: nil)
    end

    let!(:next_month) do
      create(:shipment, created_at: Time.utc(2026, 11, 1, 7), delivered_at: nil)
    end

    it { is_expected.to(eq([ delivered_in_month, first_of_month, last_of_month, next_month ])) }

    context 'with a date attribute' do
      let(:date_attribute) { 'created_at' }

      it { is_expected.to(eq([ first_of_month, last_of_month ])) }

      context 'without a date range' do
        let(:from) { nil }
        let(:to) { nil }

        it { is_expected.to(eq([ delivered_in_month, first_of_month, last_of_month, next_month ])) }
      end
    end

    context 'with a delivered date attribute' do
      let(:date_attribute) { 'delivered_at' }

      it { is_expected.to(eq([ delivered_in_month ])) }
    end

    context 'with a customer filter' do
      let(:filters) { { 'broker_customer_customer_name_eq' => broker_customer.name } }

      it { is_expected.to(eq([ first_of_month ])) }
    end

    context 'with a search filter' do
      let(:filters) { { Shipment::SEARCH_PREDICATE.to_s => last_of_month.shipper_name } }

      it { is_expected.to(eq([ last_of_month ])) }
    end

    context 'with a scope filter' do
      let(:filters) { { 'delivered' => true } }

      it { is_expected.to(eq(Shipment.delivered.order(:id).to_a)) }
    end

    context 'with a sort filter' do
      let(:filters) { { 's' => 'created_at desc' } }

      it { is_expected.to(eq([ next_month, last_of_month, first_of_month, delivered_in_month ])) }
    end

    context 'with another record type' do
      let(:contact) { create(:contact, companyable: nil) }
      let(:report) { build(:report, columns: [ 'first_name' ], filters: { 'first_name_eq' => contact.first_name }, record_type: 'Contact') }

      it { is_expected.to(eq([ contact ])) }
    end

    context 'when the user only sees some customers' do
      let(:user) { create(:broker_user) }

      before do
        create(:broker_customer_sales_rep, broker_customer:, user:)
        create(:contact_role, contact: user.contact, role: :sales_rep)
      end

      it { is_expected.to(eq([ first_of_month ])) }
    end
  end
end
