require 'rails_helper'

shared_examples_for 'authorized_attributable' do
  subject(:record) { create(described_class.name.underscore.to_sym) }

  policy_class = "#{described_class.name}Policy".constantize
  broker_attributes = policy_class::BROKER_ATTRIBUTES + policy_class::BROKER_METHODS
  customer_attributes = policy_class::CUSTOMER_ATTRIBUTES + policy_class::CUSTOMER_METHODS

  let(:broker_methods) { described_class.policy_class::BROKER_METHODS.map(&:to_s) }
  let(:customer_methods) { described_class.policy_class::CUSTOMER_METHODS.map(&:to_s) }

  it { expect(described_class.authorized_attributable?).to(be(true)) }
  it { expect(record.authorized_attributable?).to(be(true)) }

  (policy_class::BROKER_METHODS + policy_class::CUSTOMER_METHODS).each do |method|
    it { is_expected.to(respond_to(method)) }
  end

  describe '.authorized_attributes' do
    subject { described_class.authorized_attributes(authorizable) }

    let(:authorizable) { nil }

    it { is_expected.to(be_empty) }

    context 'when authorizable.broker?' do
      let(:authorizable) { create(:broker_user) }

      it { is_expected.to(eq(described_class.send(:ransackable_broker_attributes))) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { create(:customer_user) }

      it { is_expected.to(eq(described_class.send(:ransackable_customer_attributes))) }
    end
  end

  describe '.exportable_attributes' do
    subject { described_class.exportable_attributes(authorizable) }

    let(:authorizable) { nil }

    it { is_expected.to(be_empty) }

    context 'when authorizable.broker?' do
      let(:authorizable) { create(:broker_user) }

      it { is_expected.to(eq(described_class.send(:ransackable_broker_attributes) + customer_methods + broker_methods)) }
    end

    context 'when authorizable.carrier_user?' do
      let(:authorizable) { create(:carrier_user) }

      it { is_expected.to(be_empty) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { create(:customer_user) }

      it { is_expected.to(eq(described_class.send(:ransackable_customer_attributes) + customer_methods)) }
    end
  end

  describe '.exportable_preloads' do
    it { expect(described_class.exportable_preloads([])).to(be_empty) }
    it { expect(described_class.exportable_preloads([ 'unknown' ])).to(be_empty) }

    it {
      expect(described_class.exportable_preloads(described_class.method_preloads.keys))
        .to(eq(described_class.method_preloads.values))
    }
  end

  describe '.ransackable_attributes' do
    subject { described_class.ransackable_attributes(authorizable) }

    let(:authorizable) { nil }
    let(:searchable_attributes) { described_class.column_names + described_class._ransackers.keys }

    it { is_expected.to(be_empty) }

    context 'when authorizable.broker?' do
      let(:authorizable) { create(:broker_user) }

      it { is_expected.to(eq(described_class.send(:ransackable_broker_attributes) & searchable_attributes)) }
      it { is_expected.to(satisfy { |attributes| attributes.intersection(broker_methods + customer_methods).none? }) }
    end

    context 'when authorizable.carrier_user?' do
      let(:authorizable) { create(:carrier_user) }

      it { is_expected.to(be_empty) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { create(:customer_user) }

      it { is_expected.to(eq(described_class.send(:ransackable_customer_attributes) & searchable_attributes)) }
    end
  end

  describe '#authorized_attribute!' do
    let(:user) { create(:customer_user) }

    broker_attributes.each do |attribute|
      it {
        expect do
          record.authorized_attribute!(attribute, user)
        end.to(raise_error(AuthorizedAttributable::UnauthorizedAttributeError))
      }
    end

    customer_attributes.each do |attribute|
      it { expect(record.authorized_attribute!(attribute, user)).to(eq(record.public_send(attribute))) }
    end

    context 'when authorizable.broker?' do
      let(:user) { create(:broker_user) }

      (broker_attributes + customer_attributes).each do |attribute|
        it { expect(record.authorized_attribute!(attribute, user)).to(eq(record.public_send(attribute))) }
      end
    end
  end
end
