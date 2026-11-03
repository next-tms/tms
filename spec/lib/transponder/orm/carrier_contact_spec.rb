require 'rails_helper'

RSpec.describe(Transponder::ORM::CarrierContact) do
  describe '.all' do
    it { expect(described_class.pluck(:department)).to(eq(['Dispatch'])) }
  end

  describe '.primary_key' do
    it { expect(described_class.primary_key).to(eq(:id)) }
  end

  describe '#initialize' do
    let(:contact) { described_class.first }

    it { expect(contact).to(have_attributes(company_name: 'Saia', email: 'dispatch@saia.test', phone: '+18005551234')) }
    it { expect(contact).to(have_attributes(fax: nil, name: nil)) }
  end
end
