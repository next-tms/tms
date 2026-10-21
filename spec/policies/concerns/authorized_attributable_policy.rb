require 'rails_helper'

shared_examples_for 'authorized_attributable_policy' do
  let(:authorizable) { create(:user, companyable:) }
  let(:companyable) { nil }
  let(:policy) { described_class.new(record, authorizable:) }
  let(:record) { create(described_class.name.delete_suffix('Policy').underscore.to_sym) }

  context 'when broker?' do
    let(:companyable) { create(:broker) }

    (described_class::BROKER_ATTRIBUTES + described_class::BROKER_METHODS).each do |attribute|
      describe "#{attribute}_attribute?" do
        subject { policy.apply("#{attribute}_attribute?".to_sym) }

        it { is_expected.to(be(true)) }
      end
    end

    (described_class::CUSTOMER_ATTRIBUTES + described_class::CUSTOMER_METHODS).each do |attribute|
      describe "#{attribute}_attribute?" do
        subject { policy.apply("#{attribute}_attribute?".to_sym) }

        it { is_expected.to(be(true)) }
      end
    end
  end

  context 'when customer?' do
    let(:companyable) { create(:broker_customer) }

    (described_class::BROKER_ATTRIBUTES + described_class::BROKER_METHODS).each do |attribute|
      describe "#{attribute}_attribute?" do
        subject { policy.apply("#{attribute}_attribute?".to_sym) }

        it { is_expected.to(be(false)) }
      end
    end

    (described_class::CUSTOMER_ATTRIBUTES + described_class::CUSTOMER_METHODS).each do |attribute|
      describe "#{attribute}_attribute?" do
        subject { policy.apply("#{attribute}_attribute?".to_sym) }

        it { is_expected.to(be(true)) }
      end
    end
  end
end
