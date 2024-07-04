require 'rails_helper'

shared_examples_for 'authorized_attributable' do
  let(:record) { create(described_class.name.underscore.to_sym) }

  it { expect(described_class.authorized_attributable?).to(be(true)) }
  it { expect(record.authorized_attributable?).to(be(true)) }

  describe '.ransackable_attributes' do
    subject { described_class.ransackable_attributes(authorizable) }

    let(:authorizable) { nil }

    it { is_expected.to(be_empty) }

    context 'when authorizable.broker?' do
      let(:authorizable) { create(:broker_user) }

      it { is_expected.to(eq(described_class.send(:broker_ransackable_attributes))) }
    end

    context 'when authorizable.carrier_user?' do
      let(:authorizable) { create(:carrier_user) }

      it { is_expected.to(be_empty) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { create(:customer_user) }

      it { is_expected.to(eq(described_class.send(:customer_ransackable_attributes))) }
    end
  end

  describe '#attribute!' do
    let(:user) { create(:broker_user) }

    ("#{described_class.name}Policy::BROKER_ATTRIBUTES".constantize + "#{described_class.name}Policy::CUSTOMER_ATTRIBUTES".constantize).each do |attribute|
      it { expect(record.authorized_attribute!(attribute, user)).to(eq(record.public_send(attribute))) }
    end

    context 'when authorizable.broker?' do
      let(:user) { create(:customer_user) }

      "#{described_class.name}Policy::BROKER_ATTRIBUTES".constantize.each do |attribute|
        it { expect(record.authorized_attribute!(attribute, user)).to(eq(record.public_send(attribute))) }
      end

      "#{described_class.name}Policy::CUSTOMER_ATTRIBUTES".constantize.each do |attribute|
        it { expect(record.authorized_attribute!(attribute, user)).to(eq(record.public_send(attribute))) }
      end
    end

    context 'when authorizable.customer?' do
      let(:user) { create(:customer_user) }

      "#{described_class.name}Policy::BROKER_ATTRIBUTES".constantize.each do |attribute|
        it {
          expect do
            record.authorized_attribute!(attribute, user)
          end.to(raise_error(AuthorizedAttributable::UnauthorizedAttributeError))
        }
      end

      "#{described_class.name}Policy::CUSTOMER_ATTRIBUTES".constantize.each do |attribute|
        it { expect(record.authorized_attribute!(attribute, user)).to(eq(record.public_send(attribute))) }
      end
    end
  end
end
