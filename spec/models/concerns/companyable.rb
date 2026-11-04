require 'rails_helper'

shared_examples_for 'companyable' do
  let(:record) { create(described_class.to_s.underscore.to_sym) }

  describe 'relationships' do
    subject { build(described_class.to_s.underscore.to_sym) }

    it { is_expected.to(have_many(:contacts)) }
  end

  describe '#carrier?' do
    it { expect(record.carrier?).to(eq(record.is_a?(Carrier))) }
  end

  describe '#companyable_sgid' do
    it { expect(record.companyable_sgid).to(eq(record.class.find(record.id).companyable_sgid)) }
    it { expect(GlobalID::Locator.locate_signed(record.companyable_sgid)).to(eq(record)) }
  end

  describe '#customer?' do
    it { expect(record.customer?).to(eq(record.is_a?(BrokerCustomer))) }
  end
end
