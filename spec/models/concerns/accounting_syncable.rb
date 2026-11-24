require 'rails_helper'

RSpec.shared_examples('accounting_syncable') do |resource:, record:|
  let!(:integration) { create(:integration) }
  let(:record_class) { record.constantize }
  let(:remote) { record_class.new('123', loaded: true) }
  let(:host) { create(described_class.name.underscore.to_sym) }
  let(:id_column) { :"accounting_#{resource}_id" }

  before do
    allow(host).to receive(:"to_accounting_#{resource}").and_return(Accounting.const_get(resource.to_s.camelize).new)
    allow(record_class).to receive_messages(find: nil, find_by: nil, create: remote)
  end

  describe "#create_accounting_#{resource}" do
    it 'persists the remote record and stores its external id' do
      expect { host.public_send(:"create_accounting_#{resource}") }.to change { host.reload.public_send(id_column) }.from(nil)
    end
  end

  describe "#accounting_#{resource} adopting a match" do
    before do
      allow(record_class).to receive(:find_by).and_return(remote)
      host.public_send(:"accounting_#{resource}")
    end

    it { expect(host.public_send(id_column).to_s).to eq('123') }

    context 'when the host is unsaved' do
      let(:host) { build(described_class.name.underscore.to_sym) }

      it { expect(host.public_send(id_column).to_s).to eq('123') }
    end
  end
end
