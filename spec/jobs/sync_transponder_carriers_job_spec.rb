require 'rails_helper'

RSpec.describe(SyncTransponderCarriersJob) do
  let(:saia_id) { '26a6a0c0-2e95-4835-ad73-4a3c8bb38cdd' }

  describe '#perform' do
    let!(:custom) { create(:carrier, name: 'Local Freight', scac: 'LOCL') }
    let!(:linked) { create(:carrier, name: 'Old Saia', scac: 'OLDS', transponder_id: saia_id) }
    let!(:unlinked) { create(:carrier, acts_as_broker: false, consider_bol_and_pod_documents_same: false, name: 'Tql', scac: 'TQYL') }

    before { described_class.perform_now }

    it { expect(linked.reload).to(have_attributes(legal_name: 'Saia Motor Freight Line, LLC', name: 'Saia', scac: 'SAIA')) }
    it { expect(unlinked.reload).to(have_attributes(acts_as_broker: true, consider_bol_and_pod_documents_same: true, name: 'TQL')) }
    it { expect(unlinked.reload.transponder_id).to(eq('8f0c3b52-6b1e-4b8e-9a51-3f2f0d7c1e44')) }
    it { expect(custom.reload).to(have_attributes(name: 'Local Freight', transponder_id: nil)) }

    context 'when a Transponder carrier has no SCAC' do
      let(:custom) { create(:carrier, name: 'Local Freight', scac: nil) }

      before do
        stub_transponder_carriers({ 'data' => { 'fetchCarriers' => [{ 'id' => saia_id, 'name' => 'Saia', 'scac' => nil }] } })
        described_class.perform_now
      end

      it { expect(custom.reload).to(have_attributes(name: 'Local Freight', transponder_id: nil)) }
    end
  end

  describe '#sync' do
    let(:carrier) { create(:carrier, scac: 'SAIA') }
    let(:job) { described_class.new }

    before { allow(Sentry).to(receive(:capture_message)) }

    context 'when another carrier has the name' do
      before do
        create(:carrier, name: 'Saia')
        job.__send__(:sync, carrier, Transponder::ORM::Carrier.find(saia_id))
      end

      it { expect(carrier.reload.transponder_id).to(be_nil) }
      it { expect(Sentry).to(have_received(:capture_message).with("Carrier #{carrier.id} not synced: Name has already been taken")) }
    end
  end
end
