require 'rails_helper'

RSpec.describe('broker/broker_carriers/show') do
  subject { rendered }

  let(:broker_carrier) { create(:broker_carrier, carrier:) }
  let(:carrier) { create(:carrier, :saia, legal_name: 'Saia Motor Freight Line, LLC', mc_number: 92_726) }

  before do
    assign(:broker_carrier, broker_carrier)
    stub_template('broker/broker_carriers/_member_header.html.erb' => '')
    render
  end

  it { is_expected.to(include('PO Box 730532<br>Dallas, TX 75373')) }
  it { is_expected.to(include('Imported, not saved')) }
  it { is_expected.to(include('Saia Motor Freight Line, LLC')) }
  it { is_expected.to(include('11465 Johns Creek Pkwy<br>Johns Creek, GA 30097')) }
  it { is_expected.to(have_link('https://www.saia.com', href: 'https://www.saia.com')) }
  it { is_expected.to(include('29124 / 92726')) }

  context 'when the account has its own check mailing address' do
    let(:broker_carrier) { create(:broker_carrier, carrier:, check_mailing_address: create(:address, street: '9 Own St')) }

    it { is_expected.to(include('9 Own St')) }
    it { is_expected.not_to(include('Imported, not saved')) }
  end

  context 'when the carrier is custom' do
    let(:carrier) { create(:carrier, mc_number: 12_345) }

    it { is_expected.not_to(include('Imported, not saved')) }
    it { is_expected.not_to(have_link(href: 'https://www.saia.com')) }
    it { is_expected.to(include('12345')) }
  end
end
