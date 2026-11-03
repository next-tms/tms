require 'rails_helper'

RSpec.describe(FetchShipmentCarrierBOLsJob) do
  let(:configured) { create(:broker_carrier, carrier: create(:carrier, :saia), password: 'secret', username: 'user') }
  let!(:configured_shipment) { create(:shipment, broker_carrier: configured, pro: '12345678901') }
  let!(:unconfigured_shipment) { create(:shipment, broker_carrier: create(:broker_carrier)) }

  before do
    allow(FetchShipmentCarrierBOLJob).to(receive(:perform_later))
    described_class.perform_now([configured_shipment.id, unconfigured_shipment.id])
  end

  it { expect(FetchShipmentCarrierBOLJob).to(have_received(:perform_later).with(configured_shipment)) }
  it { expect(FetchShipmentCarrierBOLJob).not_to(have_received(:perform_later).with(unconfigured_shipment)) }
end
