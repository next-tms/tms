require 'rails_helper'

shared_examples_for 'companyable' do
  let(:record) { create(described_class.to_s.underscore.to_sym) }

  describe 'relationships' do
    subject { build(described_class.to_s.underscore.to_sym) }

    it { is_expected.to(have_many(:contacts)) }
  end

  describe '#broker' do
    it { expect(record.broker).to(be_a(Broker)) }
  end

  describe '#broker?' do
    it { expect(record.broker?).to(eq(record.is_a?(Broker))) }
  end

  describe '#carrier?' do
    it { expect(record.carrier?).to(eq(record.is_a?(BrokerCarrier))) }
  end

  describe '#customer?' do
    it { expect(record.customer?).to(eq(record.is_a?(BrokerCustomer))) }
  end
end
