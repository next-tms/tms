require 'rails_helper'

RSpec.describe(DocumentableService::Shipment::Base) do
  let(:shipment) { build(:shipment) }

  describe '#check_attributes' do
    [
      DocumentableService::Shipment::BrokerBOL,
      DocumentableService::Shipment::BrokerDispatchSheet,
      DocumentableService::Shipment::BrokerLabel,
      DocumentableService::Shipment::BrokerQuote
    ].each do |service|
      context "with #{service.name.demodulize}" do
        let(:check_attributes) { service.new(shipment).__send__(:check_attributes) }

        it { expect(check_attributes).to(all(satisfy { |attribute| shipment.respond_to?("saved_change_to_#{attribute}?") })) }
      end
    end
  end
end
