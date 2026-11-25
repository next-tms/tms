require 'rails_helper'

RSpec.describe(TransponderService::Input::DateTime::DeliveryRange) do
  let(:shipment) { build(:shipment) }

  describe '#delivery_from' do
    subject { described_class.new(shipment).delivery_from }

    before { allow(shipment).to(receive(:delivery_from).and_return(delivery_from)) }

    context 'when delivery_from is blank' do
      let(:delivery_from) { nil }

      it { is_expected.to(be_nil) }
    end

    context 'when delivery_from is in the future' do
      let(:delivery_from) { 1.day.from_now.change(usec: 0) }

      it { is_expected.to(eq(delivery_from.iso8601)) }
    end

    context 'when delivery_from is in the past' do
      let(:delivery_from) { 1.day.ago }

      it { is_expected.to(be_nil) }
    end
  end

  describe '#delivery_to' do
    subject { described_class.new(shipment).delivery_to }

    before { allow(shipment).to(receive(:delivery_by).and_return(delivery_by)) }

    context 'when delivery_by is blank' do
      let(:delivery_by) { nil }

      it { is_expected.to(be_nil) }
    end

    context 'when delivery_by is in the future' do
      let(:delivery_by) { 1.day.from_now.change(usec: 0) }

      it { is_expected.to(eq(delivery_by.iso8601)) }
    end

    context 'when delivery_by is in the past' do
      let(:delivery_by) { 1.day.ago }

      it { is_expected.to(be_nil) }
    end
  end
end
