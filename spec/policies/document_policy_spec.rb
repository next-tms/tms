require 'rails_helper'

RSpec.describe(DocumentPolicy) do
  let(:authorizable) { build(:broker_user) }
  let(:policy) { described_class.new(ActiveStorage::Attachment.new(name:), authorizable:) }

  describe '#view?' do
    subject { policy.apply(:view?) }

    context 'when authorizable.is_a?(BrokerCarrier)' do
      let(:policy) { described_class.new(ActiveStorage::Attachment.new(name:), authorizable: build(:broker_carrier)) }

      context 'with broker_dispatch_sheet' do
        let(:name) { 'broker_dispatch_sheet' }

        it { is_expected.to(be(true)) }
      end

      context 'with invoice' do
        let(:name) { 'invoice' }

        it { is_expected.to(be(false)) }
      end
    end

    context 'when authorizable.broker?' do
      let(:name) { 'broker_carrier_quote' }

      it { is_expected.to(be(true)) }
    end

    context 'when authorizable.carrier?' do
      let(:authorizable) { build(:user, companyable: build(:broker_carrier)) }

      DocumentPolicy::CARRIER_NAMES.each do |document_name|
        context "with #{document_name}" do
          let(:name) { document_name }

          it { is_expected.to(be(true)) }
        end
      end

      ['broker_quote', 'invoice'].each do |document_name|
        context "with #{document_name}" do
          let(:name) { document_name }

          it { is_expected.to(be(false)) }
        end
      end
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { build(:customer_user) }

      DocumentPolicy::CUSTOMER_NAMES.each do |document_name|
        context "with #{document_name}" do
          let(:name) { document_name }

          it { is_expected.to(be(true)) }
        end
      end

      ['broker_carrier_quote', 'broker_dispatch_sheet', 'carrier_bol', 'carrier_label'].each do |document_name|
        context "with #{document_name}" do
          let(:name) { document_name }

          it { is_expected.to(be(false)) }
        end
      end
    end
  end
end
