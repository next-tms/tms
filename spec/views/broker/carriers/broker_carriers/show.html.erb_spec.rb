require 'rails_helper'

RSpec.describe('broker/carriers/broker_carriers/show') do
  subject { rendered }

  let(:broker_carrier) { create(:broker_carrier, carrier:) }
  let(:carrier) { create(:carrier, :saia) }

  before do
    assign(:broker_carrier, broker_carrier)
    stub_template('broker/carriers/broker_carriers/_member_header.html.erb' => '')
    render
  end

  it { is_expected.to(include('PO Box 730532<br>Dallas, TX 75373')) }
  it { is_expected.to(include('Imported, not saved')) }

  context 'when the account has its own check mailing address' do
    let(:broker_carrier) { create(:broker_carrier, carrier:, check_mailing_address: create(:address, street: '9 Own St')) }

    it { is_expected.to(include('9 Own St')) }
    it { is_expected.not_to(include('Imported, not saved')) }
  end

  context 'when the carrier is custom' do
    let(:carrier) { create(:carrier) }

    it { is_expected.not_to(include('Imported, not saved')) }
  end
end
