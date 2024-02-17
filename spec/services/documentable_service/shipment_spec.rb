# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(DocumentableService::Shipment) do
  let(:record) { create(:shipment) }

  describe '#call' do
    Shipment::DOCUMENTABLE_TYPES.each do |document_type|
      let(:job_class) { "DocumentableService::Shipment::Create#{document_type.to_s.camelcase}Job".constantize }

      let(:service) { described_class.new(record, document_type) }
      let(:subject) { service.call! }

      before { allow(service.record).to(receive(:problematic!)) }

      it { expect { subject }.to(have_enqueued_job(job_class)) }

      context 'when not create_document?' do
        before { allow(service).to(receive(:create_document?).and_return(false)) }

        it { expect { subject }.not_to(have_enqueued_job) }
      end
    end
  end

  describe '#create_document?' do
    %i[broker_bol broker_dispatch_sheet].each do |document_type|
      let(:valid) { false }

      let(:service) { described_class.new(record, document_type) }
      let(:subject) { service.send(:create_document?) }

      before do
        allow(service).to(receive(:valid?).and_return(valid))
        allow(service).to(receive(:valid?).and_return(valid))
        allow(service.record).to(receive(:incomplete?).and_return(incomplete))
        allow(service.record).to(receive(:broker_carrier_bol_requires_tracking_number?).and_return(broker_carrier_bol_requires_tracking_number))
      end

      it { is_expected.to(eq(true)) }
    end

    %i[broker_bol broker_dispatch_sheet].each do |document_type|
      let(:broker_carrier_bol_requires_tracking_number) { false }
      let(:incomplete) { false }
      let(:pro) { Faker::Number.between(from: 1, to: 999_999_999) }
      let(:valid) { false }

      let(:record) { create(:shipment, pro:) }

      let(:service) { described_class.new(record, document_type) }
      let(:subject) { service.send(:create_document?) }

      it { is_expected.to(eq(true)) }

      context 'when record.broker_carrier_bol_requires_tracking_number?' do
        let(:broker_carrier_bol_requires_tracking_number) { true }

        it { is_expected.to(eq(true)) }

        context 'when not record.pro.present?' do
          let(:pro) { nil }

          it { is_expected.to(eq(false)) }
        end
      end

      context 'when record.incomplete?' do
        let(:incomplete) { true }

        it { is_expected.to(eq(false)) }
      end
    end
  end

  describe '#valid?' do
    Shipment::DOCUMENTABLE_TYPES.each do |document_type|
      let(:attached) { true }
      let(:broker_documents_fingerprint) { Faker::Crypto.sha256 }
      let(:fingerprint) { broker_documents_fingerprint }

      let(:service) { described_class.new(record, document_type) }
      let(:subject) { service.send(:valid?) }

      before do
        allow(service).to(receive(:attached?).and_return(attached))
        allow(service).to(receive(:fingerprint).and_return(fingerprint))
        allow(service.record).to(receive(:broker_documents_fingerprint).and_return(broker_documents_fingerprint))
      end

      it { is_expected.to(eq(true)) }

      context 'when not attached?' do
        let(:attached) { false }

        it { is_expected.to(eq(false)) }
      end

      context 'when not fingerprint == record.broker_documents_fingerprint' do
        let(:fingerprint) { Faker::Crypto.sha256 }

        it { is_expected.to(eq(false)) }
      end
    end
  end
end
