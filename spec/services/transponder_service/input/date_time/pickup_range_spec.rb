require 'rails_helper'

RSpec.describe(TransponderService::Input::DateTime::PickupRange) do
  let(:pickup_by) { 1.day.from_now.change(usec: 0) }
  let(:shipment) { build(:shipment) }

  before { allow(shipment).to(receive(:pickup_by).and_return(pickup_by)) }

  describe '#pickup_to' do
    subject { described_class.new(shipment).pickup_to }

    context 'when pickup_by is blank' do
      let(:pickup_by) { nil }

      it { is_expected.to(be_present) }
    end

    context 'when pickup_by is present' do
      it { is_expected.to(eq(pickup_by.iso8601)) }
    end
  end
end
