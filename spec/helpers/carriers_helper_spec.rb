require 'rails_helper'

RSpec.describe(CarriersHelper) do
  describe '#address_lines' do
    let(:address) { Transponder::ORM::CarrierAddress.new(id: 'hq', city: 'Austin', street: '<b>1 Main</b>') }

    it { expect(helper.address_lines(address)).to(eq('&lt;b&gt;1 Main&lt;/b&gt;<br>Austin')) }
    it { expect(helper.address_lines(address)).to(be_html_safe) }
  end
end
