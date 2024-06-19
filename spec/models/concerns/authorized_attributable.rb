require 'rails_helper'

shared_examples_for 'authorized_attributable' do
  let(:record) { create(described_class.name.underscore.to_sym) }

  describe '#attribute!' do
    context 'when authorizable.type == :broker' do
      let(:user) { create(:broker_user) }

      ("#{described_class.name}Policy::BROKER_ATTRIBUTES".constantize + "#{described_class.name}Policy::CUSTOMER_ATTRIBUTES".constantize).each do |attribute|
        it { expect(record.authorized_attribute!(attribute, user)).to(eq(record.public_send(attribute))) }
      end
    end

    context 'when authorizable.type == :customer' do
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
