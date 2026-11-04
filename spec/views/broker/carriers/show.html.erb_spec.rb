require 'rails_helper'

RSpec.describe('broker/carriers/show') do
  subject { rendered }

  let(:carrier) { create(:carrier, :saia, legal_name: 'Saia Motor Freight Line, LLC', mc_number: 92_726) }

  before do
    assign(:carrier, carrier)
    stub_template('broker/carriers/_member_header.html.erb' => '')
    render
  end

  it { is_expected.to(include('Saia Motor Freight Line, LLC')) }
  it { is_expected.to(include('11465 Johns Creek Pkwy<br>Johns Creek, GA 30097')) }
  it { is_expected.to(have_link('https://www.saia.com', href: 'https://www.saia.com')) }
  it { is_expected.to(include('29124 / 92726')) }

  context 'when the carrier is custom' do
    let(:carrier) { create(:carrier, mc_number: 12_345) }

    it { is_expected.not_to(have_link(href: 'https://www.saia.com')) }
    it { is_expected.to(include('12345')) }
  end
end
