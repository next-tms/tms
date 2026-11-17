require 'rails_helper'

RSpec.describe('broker/shipments/documents/_broker_ebol') do
  subject { rendered }

  let(:ebol) { ActiveStorage::Blob.create_and_upload!(content_type: 'application/vnd.nmfta.ebol+json', filename: '4545.ebol.json', io: StringIO.new('{}')) }
  let(:shipment) { create(:shipment, load_id: 4545).tap { |shipment| shipment.broker_ebol.attach(ebol) if ebol } }

  before do
    allow(DocumentableService).to(receive(:call))
    create(:setting, key: 'name', value: 'Broker Co')
    render(partial: 'broker/shipments/documents/broker_ebol', locals: { shipment:, this_dom_id: 'shipment_4545' })
  end

  it { is_expected.to(have_link('Download', href: rails_blob_path(shipment.broker_ebol, disposition: 'attachment'))) }
  it { is_expected.to(have_link('Send', href: send_document_broker_shipment_path(shipment, shipment_method: :broker_ebol))) }

  context 'without an eBOL' do
    let(:ebol) { nil }

    it { is_expected.not_to(have_link('Download')) }
  end
end
