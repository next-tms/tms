require 'rails_helper'

shared_examples_for 'has_companyable' do
  let(:record) { create(described_class.to_s.underscore.to_sym) }

  describe 'relationships' do
    subject { build(described_class.to_s.underscore.to_sym) }

    it { is_expected.to(belong_to(:companyable).optional) }
  end

  describe '.broker' do
    let!(:broker_record) { create(described_class.to_s.underscore.to_sym, companyable: nil) }

    before { create(described_class.to_s.underscore.to_sym, companyable: create(:broker_customer)) }

    it { expect(described_class.broker).to(contain_exactly(broker_record)) }
  end

  describe '#broker?' do
    it { expect(build(described_class.to_s.underscore.to_sym, companyable: nil)).to(be_broker) }
    it { expect(build(described_class.to_s.underscore.to_sym, companyable: build(:broker_customer))).not_to(be_broker) }
    it { expect(build(described_class.to_s.underscore.to_sym, companyable_id: 0, companyable_type: 'BrokerCustomer')).not_to(be_broker) }
  end

  describe '#carrier?' do
    it { expect(build(described_class.to_s.underscore.to_sym, companyable: build(:broker_carrier))).to(be_carrier) }
    it { expect(build(described_class.to_s.underscore.to_sym, companyable: nil)).not_to(be_carrier) }
  end

  describe '#customer?' do
    it { expect(build(described_class.to_s.underscore.to_sym, companyable: build(:broker_customer))).to(be_customer) }
    it { expect(build(described_class.to_s.underscore.to_sym, companyable: nil)).not_to(be_customer) }
  end

  describe 'validations' do
    it { expect(build(described_class.to_s.underscore.to_sym, companyable_id: 0, companyable_type: 'BrokerCustomer')).not_to(be_valid) }
  end

  describe '#companyable_type' do
    it { expect(build(described_class.to_s.underscore.to_sym, companyable_type: '').companyable_type).to(be_nil) }
  end
end
